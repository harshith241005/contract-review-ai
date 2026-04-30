from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any, List
import os
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_community.chat_models import ChatOllama

router = APIRouter()

class ChatRequest(BaseModel):
    message: str
    sla: Dict[str, Any]

@router.post("/chat")
async def chat_with_assistant(request: ChatRequest):
    try:
        # Strip out massive raw_data payload from vehicle_details to speed up LLM processing
        optimized_sla = dict(request.sla)
        if "vehicle_details" in optimized_sla and isinstance(optimized_sla["vehicle_details"], dict):
            if "raw_data" in optimized_sla["vehicle_details"]:
                optimized_sla["vehicle_details"] = dict(optimized_sla["vehicle_details"])
                del optimized_sla["vehicle_details"]["raw_data"]

        llm = ChatOllama(model="llama3", temperature=0.7)
        sys_msg = SystemMessage(content=f"""
You are a highly skilled car loan and lease negotiation assistant.
The user has uploaded a contract. Here are the extracted details:
{optimized_sla}

Answer the users question concisely, accurately, and professionally. Give actionable advice based on the contract details provided. If the information is missing from the contract, advise them to ask the dealer.
""")
        user_msg = HumanMessage(content=request.message)
        
        response = llm.invoke([sys_msg, user_msg])
        return {"response": response.content}
    except Exception as e:
        return {"response": f"I ran into an issue finding that answer: {str(e)}"}
