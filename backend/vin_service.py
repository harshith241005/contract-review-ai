"""
VIN Service Module
Fetches vehicle details and recall information from NHTSA API.
"""

import requests
from typing import Optional


def get_vehicle_details(vin: str) -> dict:
    """
    Fetch vehicle details from NHTSA API using VIN.
    
    Args:
        vin: 17-character Vehicle Identification Number
    
    Returns:
        Dictionary with decoded vehicle information
    """
    if not vin or len(vin) != 17:
        return {"error": "Invalid VIN format. Must be 17 characters."}
    
    url_values = f"https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValuesExtended/{vin}?format=json"
    url_decode = f"https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/{vin}?format=json"
    
    try:
        # Primary path: DecodeVinValuesExtended has normalized fields and is
        # generally more complete for common VIN lookups.
        values_response = requests.get(url_values, timeout=10)
        values_response.raise_for_status()
        values_data = values_response.json()
        values_results = values_data.get("Results", [])

        if values_results:
            row = values_results[0] or {}
            vehicle_info = {
                "vin": vin,
                "make": row.get("Make"),
                "model": row.get("Model"),
                "year": row.get("ModelYear"),
                "body_type": row.get("BodyClass"),
                "vehicle_type": row.get("VehicleType"),
                "drive_type": row.get("DriveType"),
                "cylinders": row.get("EngineCylinders"),
                "engine_displacement": row.get("DisplacementL"),
                "fuel_type": row.get("FuelTypePrimary"),
                "transmission": row.get("TransmissionStyle"),
                "plant_city": row.get("PlantCity"),
                "plant_country": row.get("PlantCountry"),
                "manufacturer": row.get("Manufacturer"),
                "doors": row.get("Doors"),
                "seat_belt_type": row.get("SeatBeltsAll"),
                "gvwr": row.get("GVWR"),
                "raw_data": values_results,
            }

            # If essential fields exist, return immediately.
            if vehicle_info.get("make") and vehicle_info.get("model") and vehicle_info.get("year"):
                return vehicle_info

        # Fallback path: DecodeVin variable/value format.
        decode_response = requests.get(url_decode, timeout=10)
        decode_response.raise_for_status()
        decode_data = decode_response.json()

        results = decode_data.get("Results", [])
        vehicle_info = {"vin": vin}

        for item in results:
            variable = item.get("Variable", "")
            value = item.get("Value")

            if value and value not in ["Not Applicable", ""]:
                field_mapping = {
                    "Make": "make",
                    "Model": "model",
                    "Model Year": "year",
                    "Body Class": "body_type",
                    "Vehicle Type": "vehicle_type",
                    "Drive Type": "drive_type",
                    "Engine Number of Cylinders": "cylinders",
                    "Engine Displacement (L)": "engine_displacement",
                    "Fuel Type - Primary": "fuel_type",
                    "Transmission Style": "transmission",
                    "Plant City": "plant_city",
                    "Plant Country": "plant_country",
                    "Manufacturer Name": "manufacturer",
                    "Doors": "doors",
                    "Seat Belts All": "seat_belt_type",
                    "GVWR": "gvwr",
                }

                if variable in field_mapping:
                    vehicle_info[field_mapping[variable]] = value

        vehicle_info["raw_data"] = results
        return vehicle_info
        
    except requests.exceptions.Timeout:
        return {"error": "Request timed out. Please try again."}
    except requests.exceptions.RequestException as e:
        return {"error": f"Failed to fetch vehicle details: {str(e)}"}


def get_vehicle_recalls(vin: str) -> dict:
    """
    Fetch recall information for a vehicle from NHTSA.
    
    Args:
        vin: 17-character Vehicle Identification Number
    
    Returns:
        Dictionary with recall information
    """
    if not vin or len(vin) != 17:
        return {"error": "Invalid VIN format. Must be 17 characters."}
    
    url = f"https://api.nhtsa.gov/recalls/recallsByVehicle?make=&model=&modelYear="
    
    # First get vehicle details to get make/model/year
    vehicle = get_vehicle_details(vin)
    
    if "error" in vehicle:
        return vehicle
    
    make = vehicle.get("make", "")
    model = vehicle.get("model", "")
    year = vehicle.get("year", "")
    
    if not all([make, model, year]):
        return {"error": "Could not determine vehicle make/model/year for recall lookup."}
    
    recall_url = f"https://api.nhtsa.gov/recalls/recallsByVehicle?make={make}&model={model}&modelYear={year}"
    
    try:
        response = requests.get(recall_url, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        recalls = data.get("results", [])
        
        return {
            "vin": vin,
            "vehicle": f"{year} {make} {model}",
            "recall_count": len(recalls),
            "recalls": [
                {
                    "campaign_number": r.get("NHTSACampaignNumber"),
                    "component": r.get("Component"),
                    "summary": r.get("Summary"),
                    "consequence": r.get("Consequence"),
                    "remedy": r.get("Remedy"),
                    "report_date": r.get("ReportReceivedDate")
                }
                for r in recalls
            ]
        }
        
    except requests.exceptions.RequestException as e:
        return {"error": f"Failed to fetch recall information: {str(e)}"}


def validate_vin(vin: str) -> dict:
    """
    Validate a VIN using the check digit algorithm.
    
    Args:
        vin: Vehicle Identification Number to validate
    
    Returns:
        Dictionary with validation result
    """
    if not vin:
        return {"valid": False, "error": "VIN is empty"}
    
    if len(vin) != 17:
        return {"valid": False, "error": f"VIN must be 17 characters, got {len(vin)}"}
    
    vin = vin.upper()
    
    # VINs cannot contain I, O, or Q
    invalid_chars = set('IOQ')
    if any(c in invalid_chars for c in vin):
        return {"valid": False, "error": "VIN cannot contain I, O, or Q"}
    
    # Check if all characters are valid
    valid_chars = set('0123456789ABCDEFGHJKLMNPRSTUVWXYZ')
    if not all(c in valid_chars for c in vin):
        return {"valid": False, "error": "VIN contains invalid characters"}
    
    # Transliteration values
    transliteration = {
        'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
        'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
        'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
        '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9
    }
    
    # Weight factors for each position
    weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]
    
    # Calculate checksum
    total = 0
    for i, char in enumerate(vin):
        total += transliteration.get(char, 0) * weights[i]
    
    remainder = total % 11
    check_digit = 'X' if remainder == 10 else str(remainder)
    
    if vin[8] == check_digit:
        return {"valid": True, "vin": vin}
    else:
        return {"valid": False, "error": f"Check digit mismatch. Expected {check_digit}, got {vin[8]}"}

