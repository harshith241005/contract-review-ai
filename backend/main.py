import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from backend.db import save_contract, save_sla, get_connection, create_contracts_table, create_sla_table
from backend.pdf_reader import extract_text_from_pdf
from backend.contract_analyzer import analyze_contract
from backend.vin_service import get_vehicle_details
from backend.negotiation_assistant import generate_negotiation_points
from backend.fairness_engine import calculate_fairness_score
import json
import traceback
import requests

# Initialize database tables on startup
create_contracts_table()
create_sla_table()

app = FastAPI(
    title="Car Loan Assistant API",
    description="API for analyzing car lease/loan contracts",
    version="1.0.0"
)

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models for request/response
class NegotiationRequest(BaseModel):
    sla: Dict[str, Any]
    fairness: Optional[Dict[str, Any]] = None

class PriceEstimateRequest(BaseModel):
    make: str
    model: str
    year: str
    zip_code: Optional[str] = None

@app.get("/")
def home():
    return {"message": "Car Loan Assistant API is running", "version": "1.0.0"}

@app.post("/analyze")
async def analyze_contract_api(file: UploadFile):
    try:
        file_bytes = await file.read()
        filename = file.filename.lower() if file.filename else ""
        
        # Debug logging
        print(f"[ANALYZE] Received file: '{file.filename}', size: {len(file_bytes)} bytes")
        print(f"[ANALYZE] Filename lowercase: '{filename}'")
        
        if not file_bytes or len(file_bytes) == 0:
            return {"error": "Empty file received. Please select a valid file."}
        
        # Determine file type and extract text
        if filename.endswith('.pdf'):
            print("[ANALYZE] Processing as PDF...")
            text = extract_text_from_pdf(file_bytes)
        elif filename.endswith('.docx'):
            print("[ANALYZE] Processing as DOCX...")
            from backend.pdf_reader import extract_text_from_docx
            text = extract_text_from_docx(file_bytes)
        elif filename.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif')):
            # Handle image files with OCR
            print("[ANALYZE] Processing as Image (OCR)...")
            from backend.pdf_reader import extract_text_from_image
            text = extract_text_from_image(file_bytes)
        else:
            print(f"[ANALYZE] Unsupported file type: '{filename}'")
            return {"error": f"Unsupported file type '{filename}'. Please upload PDF, DOCX, or image files (JPG, PNG)."}

        print(f"[ANALYZE] Extracted text length: {len(text) if text else 0}")
        
        if not text.strip():
            # Provide more helpful error message
            if filename.endswith('.pdf'):
                return {"error": "No readable text extracted. This PDF may be image-based (scanned). Try uploading a text-based PDF, or install Tesseract OCR for scanned document support."}
            elif filename.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif')):
                return {"error": "No text could be extracted from the image. Please ensure Tesseract OCR is installed, or try uploading a PDF or DOCX file."}
            return {"error": "No readable text extracted from the document."}

        contract_id = save_contract(file.filename, text)
        sla = analyze_contract(text)
        save_sla(contract_id, sla)
        
        # Calculate fairness score
        fairness = calculate_fairness_score(sla)
        
        # Generate negotiation points
        points = generate_negotiation_points(sla, fairness)

        return {
            "contract_id": contract_id,
            "file_name": file.filename,
            "sla": sla,
            "fairness": fairness,
            "negotiation_points": points
        }

    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}

@app.get("/vin/{vin}")
async def vin_lookup(vin: str):
    """
    Look up vehicle information by VIN using NHTSA API
    """
    try:
        if len(vin) != 17:
            return {"error": "VIN must be exactly 17 characters"}
        
        vehicle_data = get_vehicle_details(vin)
        
        # Parse NHTSA response
        results = vehicle_data.get("Results", [])
        parsed_data = {"vin": vin}
        
        for item in results:
            variable = item.get("Variable")
            value = item.get("Value")
            if variable and value:
                parsed_data[variable] = value
        
        # Extract key fields
        vehicle_info = {
            "vin": vin,
            "make": parsed_data.get("Make"),
            "model": parsed_data.get("Model"),
            "year": parsed_data.get("Model Year"),
            "manufacturer": parsed_data.get("Manufacturer Name"),
            "vehicle_type": parsed_data.get("Vehicle Type"),
            "engine_info": parsed_data.get("Engine Model"),
            "fuel_type": parsed_data.get("Fuel Type - Primary"),
            "transmission": parsed_data.get("Transmission Style"),
        }
        
        # Get recalls
        try:
            recall_url = f"https://api.nhtsa.gov/recalls/recallsByVehicle?make={vehicle_info['make']}&model={vehicle_info['model']}&modelYear={vehicle_info['year']}"
            recall_response = requests.get(recall_url, timeout=10)
            if recall_response.status_code == 200:
                recall_data = recall_response.json()
                vehicle_info["recalls"] = recall_data.get("results", [])
        except Exception:
            vehicle_info["recalls"] = []
        
        return vehicle_info
        
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}

@app.post("/negotiate")
async def get_negotiation_tips(request: NegotiationRequest):
    """
    Generate negotiation points based on SLA data
    """
    try:
        fairness = request.fairness or calculate_fairness_score(request.sla)
        points = generate_negotiation_points(request.sla, fairness)
        
        return {
            "points": points,
            "fairness": fairness
        }
        
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}

@app.get("/price-estimate")
async def get_price_estimate(make: str, model: str, year: str, zip: Optional[str] = None):
    """
    Get estimated price range for a vehicle (using NHTSA data as baseline)
    Note: This is a simplified implementation. In production, 
    integrate with Edmunds, KBB, or similar pricing APIs.
    """
    try:
        # Get vehicle specifications from NHTSA
        url = f"https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear/make/{make}/modelyear/{year}?format=json"
        response = requests.get(url, timeout=10)
        
        if response.status_code != 200:
            return {"error": "Could not fetch vehicle data"}
        
        data = response.json()
        models = data.get("Results", [])
        
        # Simple price estimation based on vehicle type and age
        current_year = 2026
        vehicle_age = current_year - int(year)
        
        # Base prices by category (simplified)
        base_prices = {
            "sedan": 25000,
            "suv": 35000,
            "truck": 40000,
            "compact": 20000,
            "luxury": 50000,
            "default": 28000
        }
        
        # Determine category from model name (simplified logic)
        model_lower = model.lower()
        if any(x in model_lower for x in ["camry", "accord", "civic", "corolla"]):
            category = "sedan"
        elif any(x in model_lower for x in ["rav4", "cr-v", "explorer", "highlander"]):
            category = "suv"
        elif any(x in model_lower for x in ["f-150", "silverado", "ram", "tundra"]):
            category = "truck"
        elif any(x in model_lower for x in ["fit", "yaris", "versa"]):
            category = "compact"
        elif any(x in model_lower for x in ["bmw", "mercedes", "lexus", "audi"]):
            category = "luxury"
        else:
            category = "default"
        
        base_price = base_prices[category]
        
        # Depreciation: ~15% first year, ~10% per year after
        if vehicle_age <= 0:
            estimated_price = base_price
        elif vehicle_age == 1:
            estimated_price = base_price * 0.85
        else:
            estimated_price = base_price * 0.85 * (0.90 ** (vehicle_age - 1))
        
        # Price range
        low_price = int(estimated_price * 0.85)
        high_price = int(estimated_price * 1.15)
        
        return {
            "make": make,
            "model": model,
            "year": year,
            "category": category,
            "estimated_price": int(estimated_price),
            "price_range": {
                "low": low_price,
                "high": high_price
            },
            "disclaimer": "Prices are estimates based on vehicle category and age. Actual prices vary by condition, mileage, and location."
        }
        
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.get("/contracts")
async def get_contracts():
    """Get list of all analyzed contracts"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.id, c.file_name, c.created_at, s.sla_json
            FROM contracts c
            LEFT JOIN sla_extractions s ON c.id = s.contract_id
            ORDER BY c.created_at DESC
        """)
        rows = cursor.fetchall()
        conn.close()
        
        contracts = []
        for row in rows:
            sla_data = json.loads(row[3]) if row[3] else {}
            contracts.append({
                "id": row[0],
                "file_name": row[1],
                "created_at": row[2],
                "sla": sla_data
            })
        
        return {"contracts": contracts, "count": len(contracts)}
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/contracts/{contract_id}")
async def get_contract(contract_id: int):
    """Get a specific contract by ID"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.id, c.file_name, c.raw_text, c.created_at, s.sla_json
            FROM contracts c
            LEFT JOIN sla_extractions s ON c.id = s.contract_id
            WHERE c.id = ?
        """, (contract_id,))
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            raise HTTPException(status_code=404, detail="Contract not found")
        
        sla_data = json.loads(row[4]) if row[4] else {}
        fairness = calculate_fairness_score(sla_data)
        
        return {
            "id": row[0],
            "file_name": row[1],
            "raw_text": row[2][:500] + "..." if len(row[2]) > 500 else row[2],
            "created_at": row[3],
            "sla": sla_data,
            "fairness": fairness
        }
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.delete("/contracts/{contract_id}")
async def delete_contract(contract_id: int):
    """Delete a contract by ID"""
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Delete SLA extraction first (foreign key constraint)
        cursor.execute("DELETE FROM sla_extractions WHERE contract_id = ?", (contract_id,))
        # Delete contract
        cursor.execute("DELETE FROM contracts WHERE id = ?", (contract_id,))
        
        if cursor.rowcount == 0:
            conn.close()
            raise HTTPException(status_code=404, detail="Contract not found")
        
        conn.commit()
        conn.close()
        
        return {"message": f"Contract {contract_id} deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.post("/analyze-llm")
async def analyze_contract_with_llm(file: UploadFile):
    """
    Analyze contract using LLM (GPT-4) for more accurate extraction.
    Requires OPENAI_API_KEY in environment.
    """
    try:
        from backend.llm_sla_extractor import extract_sla_with_llm
        
        pdf_bytes = await file.read()
        text = extract_text_from_pdf(pdf_bytes)

        if not text.strip():
            return {"error": "No readable text extracted"}

        contract_id = save_contract(file.filename, text)
        
        # Use LLM for extraction
        sla = extract_sla_with_llm(text)
        save_sla(contract_id, sla)
        
        # Calculate fairness score
        fairness = calculate_fairness_score(sla)

        return {
            "contract_id": contract_id,
            "file_name": file.filename,
            "sla": sla,
            "fairness": fairness,
            "extraction_method": "llm"
        }

    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/compare")
async def compare_contracts(ids: str):
    """
    Compare multiple contracts.
    Pass contract IDs as comma-separated string: ?ids=1,2,3
    """
    try:
        contract_ids = [int(x.strip()) for x in ids.split(",")]
        
        if len(contract_ids) < 2:
            return {"error": "Please provide at least 2 contract IDs to compare"}
        
        conn = get_connection()
        cursor = conn.cursor()
        
        contracts = []
        for cid in contract_ids:
            cursor.execute("""
                SELECT c.id, c.file_name, c.created_at, s.sla_json
                FROM contracts c
                LEFT JOIN sla_extractions s ON c.id = s.contract_id
                WHERE c.id = ?
            """, (cid,))
            row = cursor.fetchone()
            
            if row:
                sla_data = json.loads(row[3]) if row[3] else {}
                fairness = calculate_fairness_score(sla_data)
                contracts.append({
                    "id": row[0],
                    "file_name": row[1],
                    "created_at": row[2],
                    "sla": sla_data,
                    "fairness": fairness
                })
        
        conn.close()
        
        # Find best contract based on fairness score
        best_contract = max(contracts, key=lambda x: x.get("fairness", {}).get("fairness_score", 0))
        
        return {
            "contracts": contracts,
            "comparison_count": len(contracts),
            "best_contract_id": best_contract["id"],
            "recommendation": f"Contract '{best_contract['file_name']}' has the highest fairness score"
        }
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/vin/{vin}/recalls")
async def get_recalls(vin: str):
    """
    Get recall information for a vehicle by VIN.
    """
    try:
        from backend.vin_service import get_vehicle_recalls
        recalls = get_vehicle_recalls(vin)
        return recalls
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/vin/{vin}/validate")
async def validate_vin_endpoint(vin: str):
    """
    Validate a VIN using the check digit algorithm.
    """
    try:
        from backend.vin_service import validate_vin
        result = validate_vin(vin)
        return result
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


class NegotiationEmailRequest(BaseModel):
    sla: Dict[str, Any]
    points: List[str]
    customer_name: Optional[str] = "[Your Name]"


@app.post("/negotiate/email")
async def generate_email(request: NegotiationEmailRequest):
    """
    Generate a negotiation email template.
    """
    try:
        from backend.negotiation_assistant import generate_negotiation_email
        email = generate_negotiation_email(request.sla, request.points, request.customer_name)
        return {"email": email}
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/negotiate/questions")
async def get_dealer_questions():
    """
    Get a list of important questions to ask the dealer.
    """
    try:
        from backend.negotiation_assistant import generate_questions_list
        questions = generate_questions_list()
        return {"questions": questions}
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


class TextAnalyzeRequest(BaseModel):
    text: str


@app.post("/analyze-text")
async def analyze_text(request: TextAnalyzeRequest):
    """
    Analyze contract text directly (without file upload).
    Useful for testing or when text is already extracted.
    """
    try:
        if not request.text.strip():
            return {"error": "No text provided"}

        contract_id = save_contract("direct_text_input", request.text)
        sla = analyze_contract(request.text)
        save_sla(contract_id, sla)
        
        # Calculate fairness score
        fairness = calculate_fairness_score(sla)
        
        # Generate negotiation points
        points = generate_negotiation_points(sla, fairness)

        return {
            "contract_id": contract_id,
            "sla": sla,
            "fairness": fairness,
            "negotiation_points": points
        }

    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/samples")
async def list_samples():
    """
    List available sample contracts in the samples folder.
    """
    try:
        samples_dir = os.path.join(os.path.dirname(__file__), "..", "samples")
        if not os.path.exists(samples_dir):
            return {"samples": [], "message": "Samples folder not found"}
        
        files = []
        for f in os.listdir(samples_dir):
            if f.endswith(('.pdf', '.docx')):
                file_path = os.path.join(samples_dir, f)
                files.append({
                    "name": f,
                    "type": "pdf" if f.endswith('.pdf') else "docx",
                    "size_kb": round(os.path.getsize(file_path) / 1024, 2)
                })
        
        return {"samples": files, "count": len(files)}
    except Exception as e:
        return {"error": str(e)}


@app.get("/samples/{filename}/analyze")
async def analyze_sample(filename: str):
    """
    Analyze a sample contract from the samples folder.
    """
    try:
        samples_dir = os.path.join(os.path.dirname(__file__), "..", "samples")
        file_path = os.path.join(samples_dir, filename)
        
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Sample file not found")
        
        with open(file_path, 'rb') as f:
            file_bytes = f.read()
        
        # Extract text based on file type
        if filename.lower().endswith('.pdf'):
            text = extract_text_from_pdf(file_bytes)
        elif filename.lower().endswith('.docx'):
            from backend.pdf_reader import extract_text_from_docx
            text = extract_text_from_docx(file_bytes)
        else:
            return {"error": "Unsupported file type"}
        
        if not text.strip():
            return {"error": "No readable text extracted from sample"}
        
        contract_id = save_contract(filename, text)
        sla = analyze_contract(text)
        save_sla(contract_id, sla)
        
        fairness = calculate_fairness_score(sla)
        points = generate_negotiation_points(sla, fairness)
        
        return {
            "contract_id": contract_id,
            "file_name": filename,
            "sla": sla,
            "fairness": fairness,
            "negotiation_points": points,
            "extracted_text_preview": text[:500] + "..." if len(text) > 500 else text
        }
    except HTTPException:
        raise
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}


@app.get("/api-info")
async def api_info():
    """
    Get information about available API endpoints.
    """
    return {
        "name": "Car Loan Assistant API",
        "version": "1.0.0",
        "endpoints": {
            "POST /analyze": "Upload and analyze PDF/DOCX contract",
            "POST /analyze-llm": "Analyze contract using LLM (requires OpenAI API key)",
            "POST /analyze-text": "Analyze contract text directly",
            "GET /contracts": "List all analyzed contracts",
            "GET /contracts/{id}": "Get a specific contract",
            "DELETE /contracts/{id}": "Delete a contract",
            "GET /compare?ids=1,2,3": "Compare multiple contracts",
            "GET /samples": "List sample contracts",
            "GET /samples/{filename}/analyze": "Analyze a sample contract",
            "GET /vin/{vin}": "Look up vehicle information by VIN",
            "GET /vin/{vin}/recalls": "Get recall information for a vehicle",
            "GET /vin/{vin}/validate": "Validate a VIN",
            "POST /negotiate": "Get negotiation tips",
            "POST /negotiate/email": "Generate negotiation email",
            "GET /negotiate/questions": "Get dealer questions list",
            "GET /price-estimate": "Get price estimate for a vehicle",
            "GET /health": "Health check endpoint"
        }
    }


