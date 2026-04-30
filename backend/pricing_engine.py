import os
import json
import requests
import traceback
from typing import Dict, Any, Optional
from langchain_community.chat_models import ChatOllama
from langchain_core.messages import HumanMessage

def get_ai_price_estimate(make: str, model: str, year: str) -> Optional[dict]:
    """
    100% Free AI-powered price estimation using local Ollama.
    """
    try:
        llm = ChatOllama(model='llama3', temperature=0)
        prompt = f'What is the estimated fair market price for a used {year} {make} {model} in good condition? Reply ONLY with JSON like {{"estimated_price": 15000, "low": 13000, "high": 17000}} with NO markdown formatting, NO backticks, and NO other text.'
        msg = HumanMessage(content=prompt)
        response_text = llm.invoke([msg]).content.strip()
        
        # Clean up any potential markdown
        if response_text.startswith("```json"):
            response_text = response_text.replace("```json", "").replace("```", "").strip()
        elif response_text.startswith("```"):
            response_text = response_text.replace("```", "").strip()
            
        data = json.loads(response_text)
        if "estimated_price" in data:
            return {
                "make": make,
                "model": model,
                "year": year,
                "estimated_price": int(data["estimated_price"]),
                "price_range": {
                    "low": int(data.get("low", data["estimated_price"] * 0.85)),
                    "high": int(data.get("high", data["estimated_price"] * 1.15))
                },
                "source": "Local AI Estimator (Ollama)",
                "disclaimer": "This is an AI-generated price estimate using Llama 3. It may not reflect exact real-time local market conditions."
            }
        return None
    except Exception as e:
        print(f"Error fetching AI price estimate: {e}")
        return None

def get_marketcheck_estimate(make: str, model: str, year: str, zip_code: Optional[str] = None) -> Optional[dict]:
    """
    Tries to get a real pricing estimate from the Marketcheck API.
    """
    api_key = os.getenv("MARKETCHECK_API_KEY")
    if not api_key:
        return None
        
    try:
        url = "https://marketcheck-prod.apigee.net/v2/search/car/active"
        params = {
            "api_key": api_key,
            "make": make,
            "model": model,
            "year": year,
            "rows": 10,
        }
        if zip_code:
            params["zip"] = zip_code
            params["radius"] = 50
            
        response = requests.get(url, params=params, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            listings = data.get("listings", [])
            
            prices = [listing.get("price") for listing in listings if listing.get("price") is not None]
            if len(prices) > 0:
                avg_price = sum(prices) / len(prices)
                low_price = min(prices)
                high_price = max(prices)
                
                return {
                    "make": make,
                    "model": model,
                    "year": year,
                    "estimated_price": int(avg_price),
                    "price_range": {
                        "low": int(low_price),
                        "high": int(high_price)
                    },
                    "source": "Marketcheck API",
                    "disclaimer": "Prices are live estimates based on active inventory via Marketcheck API."
                }
        return None
    except Exception as e:
        print(f"Error fetching Marketcheck pricing: {e}")
        return None

def get_heuristic_price_estimate(make: str, model: str, year: str) -> dict:
    """Fallback heuristic logic."""
    try:
        # Get vehicle specifications from NHTSA API
        url = f"https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear/make/{make}/modelyear/{year}?format=json"
        response = requests.get(url, timeout=10)
        
        data = response.json() if response.status_code == 200 else {"Results": []}
        models = data.get("Results", [])
        
        # Calculate vehicle age
        current_year = 2026
        vehicle_age = current_year - int(year)
        
        base_prices = {
            "luxury_suv": 70000,
            "luxury_sedan": 60000,
            "luxury": 50000,
            "premium_suv": 45000,
            "premium_sedan": 40000,
            "mid_size_suv": 35000,
            "mid_size_sedan": 25000,
            "suv": 32000,
            "sedan": 24000,
            "truck": 38000,
            "compact": 18000,
            "hatchback": 16000,
            "mpv": 28000,
            "crossover": 30000,
            "default": 26000
        }
        
        model_lower = model.lower().strip()
        make_lower = make.lower().strip()
        known_models = [str(m.get("Model_Name", "")).lower() for m in models if m.get("Model_Name")]
        model_token = "".join(ch for ch in model_lower if ch.isalnum() or ch.isspace()).strip()
        relevant_models = []
        if model_token:
            for km in known_models:
                if model_token in km or km in model_token:
                    relevant_models.append(km)
            relevant_models = relevant_models[:10]
        lookup_text = f"{make_lower} {model_lower} {' '.join(relevant_models)}"
        
        luxury_makes = ["bmw", "mercedes", "audi", "lexus", "acura", "infiniti", "porsche", "jaguar", "land rover", "genesis", "volvo", "rolls royce", "bentley", "lamborghini"]
        luxury_suv_keywords = ["range rover", "x7", "gl 550", "gle 580", "q7", "rx 570", "lx 600"]
        luxury_sedan_keywords = ["7 series", "s-class", "a8", "ls 500", "tlx", "q70", "panamera"]
        premium_suv_keywords = ["x5", "x3", "q7", "q5", "glc", "rx", "nx", "tx", "grand cherokee", "pathfinder", "pilot"]
        premium_sedan_keywords = ["a6", "a4", "5 series", "3 series", "c-class", "e-class", "es", "is", "accord", "optima"]
        mid_size_suv_keywords = ["highlander", "santa fe", "explorer", "rav4", "cr-v", "tiguan", "sportage", "sorento", "endeavour"]
        mid_size_sedan_keywords = ["camry", "accord", "maxima", "altima", "optima", "sonata", "k5", "assent", "rapid"]
        suv_keywords = ["rav4", "cr-v", "explorer", "escape", "edge", "forester", "outback", "equinox", "traverse", "murano", "rogue", "qashqai", "duster", "creta", "seltos", "xcent", "wrangler", "cherokee", "compass"]
        sedan_keywords = ["camry", "accord", "civic", "corolla", "elantra", "sonata", "altima", "sentra", "jetta", "passat", "mazda3", "model 3", "focus", "cruze", "lancer", "verna", "swift", "baleno"]
        truck_keywords = ["f-150", "silverado", "ram", "tundra", "tacoma", "colorado", "ranger", "canyon", "sierra", "transit"]
        compact_keywords = ["fit", "yaris", "versa", "rio", "spark", "picanto", "micra", "i10", "i20", "swift", "baleno"]
        hatchback_keywords = ["golf", "focus", "fiesta", "polo", "ibiza", "clio", "astra", "i30", "peugeot 208", "renault clio"]
        mpv_keywords = ["odyssey", "sienna", "pacifica", "quest", "carnival", "innova", "ertiga", "marazzo"]
        crossover_keywords = ["crosstrek", "c-hr", "kicks", "rogue", "juke", "ecosport"]
        
        category = "default"
        
        if any(lm in lookup_text for lm in luxury_makes):
            if any(lsv in lookup_text for lsv in luxury_suv_keywords):
                category = "luxury_suv"
            elif any(lsd in lookup_text for lsd in luxury_sedan_keywords):
                category = "luxury_sedan"
            else:
                category = "luxury"
        elif any(psv in lookup_text for psv in premium_suv_keywords):
            category = "premium_suv"
        elif any(psd in lookup_text for psd in premium_sedan_keywords):
            category = "premium_sedan"
        elif any(msv in lookup_text for msv in mid_size_suv_keywords):
            category = "mid_size_suv"
        elif any(msd in lookup_text for msd in mid_size_sedan_keywords):
            category = "mid_size_sedan"
        elif any(x in lookup_text for x in suv_keywords):
            category = "suv"
        elif any(x in lookup_text for x in sedan_keywords):
            category = "sedan"
        elif any(x in lookup_text for x in truck_keywords):
            category = "truck"
        elif any(x in lookup_text for x in mpv_keywords):
            category = "mpv"
        elif any(x in lookup_text for x in crossover_keywords):
            category = "crossover"
        elif any(x in lookup_text for x in hatchback_keywords):
            category = "hatchback"
        elif any(x in lookup_text for x in compact_keywords):
            category = "compact"
        elif make_lower in ["tata", "maruti", "mahindra"]:
            if "suv" in model_lower or "xuv" in model_lower or "creta" in model_lower or "seltos" in model_lower:
                category = "suv"
            elif "innova" in model_lower or "ertiga" in model_lower or "marazzo" in model_lower:
                category = "mpv"
            else:
                category = "compact"
        elif make_lower in ["hyundai", "kia", "skoda", "volkswagen"]:
            category = "sedan"
        elif make_lower in ["ford", "chevrolet", "gmc"]:
            category = "truck" if "f-" in model_lower or "silverado" in model_lower or "ram" in model_lower else "sedan"
        elif make_lower in ["jeep", "land rover"]:
            category = "suv"
        elif make_lower in ["tesla"]:
            category = "premium_sedan"
        else:
            category = "default"
        
        base_price = base_prices.get(category, base_prices["default"])
        
        if vehicle_age <= 0:
            estimated_price = base_price
        elif vehicle_age == 1:
            estimated_price = base_price * 0.85
        elif vehicle_age <= 5:
            estimated_price = base_price * 0.85 * (0.90 ** (vehicle_age - 1))
        else:
            estimated_price = base_price * 0.85 * (0.90 ** 4) * (0.93 ** (vehicle_age - 5))
        
        if vehicle_age > 15:
            estimated_price = max(estimated_price, base_price * 0.15)
        
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
            "vehicle_age": vehicle_age,
            "source": "Heuristic Algorithm",
            "disclaimer": "Prices are heuristic estimates based on vehicle category, age, and depreciation patterns. Actual prices vary by condition, mileage, location, market demand, and seller. For accurate pricing, consult Edmunds, KBB, CarWale, or local dealerships."
        }
        
    except Exception as e:
        traceback.print_exc()
        return {"error": str(e)}

def get_indian_price_estimate(make: str, model: str, year: str) -> Optional[dict]:
    """
    Attempts to get a real pricing estimate using an Indian car pricing API via RapidAPI 
    (e.g., CarWale or CarDekho wrapper). Needs RAPIDAPI_KEY in .env.
    """
    api_key = os.getenv("RAPIDAPI_KEY")
    if not api_key:
        return None
        
    try:
        # Example Indian Car API endpoint (Car Data or Indian Car Pricing via RapidAPI)
        # Note: Replace with the exact endpoint you subscribe to on RapidAPI.
        url = "https://indian-car-data.p.rapidapi.com/car/price-estimate"
        
        headers = {
            "X-RapidAPI-Key": api_key,
            "X-RapidAPI-Host": "indian-car-data.p.rapidapi.com"
        }
        
        params = {
            "make": make,
            "model": model,
            "year": year
        }
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            # Assuming the API returns a structured response like {"average_price_inr": 450000, "range": {...}}
            inr_price = data.get("average_price_inr")
            
            if inr_price:
                # Convert INR to USD for backend consistency if necessary, or return INR
                # We'll return it as the 'estimated_price'. For now, let's keep it straight.
                low_price = data.get("low_price_inr", inr_price * 0.85)
                high_price = data.get("high_price_inr", inr_price * 1.15)
                
                return {
                    "make": make,
                    "model": model,
                    "year": year,
                    "estimated_price": int(inr_price),
                    "price_range": {
                        "low": int(low_price),
                        "high": int(high_price)
                    },
                    "currency": "INR",
                    "source": "Indian Car Pricing API",
                    "disclaimer": "Live pricing estimate via Indian car market data (CarWale/CarDekho equivalent)."
                }
        return None
    except Exception as e:
        print(f"Error fetching Indian Car API pricing: {e}")
        return None

def get_real_price_estimate(make: str, model: str, year: str, zip_code: Optional[str] = None) -> dict:
    """
    Main function to get a price estimate.
    Attempts Indian localized API first, then Marketcheck API, 
    falling back to heuristic logic on failure or missing API key.
    """
    # 1. Try Indian specifics if we have the RapidAPI key
    # (Best for Indian context: Tata, Maruti, Mahindra, Hyundai, etc.)
    indian_result = get_indian_price_estimate(make, model, year)
    if indian_result:
        return indian_result

    # 2. Try the global Marketcheck API
    marketcheck_result = get_marketcheck_estimate(make, model, year, zip_code)
    if marketcheck_result:
        return marketcheck_result

    # 3. Try the completely free Local AI (Ollama)
    ai_result = get_ai_price_estimate(make, model, year)
    if ai_result:
        return ai_result

    # 4. Fallback smoothly to our integrated heuristic engine
    return get_heuristic_price_estimate(make, model, year)
