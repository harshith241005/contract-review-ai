import copy
import json
import os

from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from backend.sla_schema import SLA_SCHEMA

# Load environment variables
load_dotenv()

SYSTEM_PROMPT = """
You are an AI assistant specialized in analyzing car lease and car loan contracts.
Extract ONLY the requested fields.
Return STRICT JSON only.
Do NOT explain.
Do NOT guess missing values.
Use null if information is not present.
""".strip()


def _empty_schema() -> dict:
    return copy.deepcopy(SLA_SCHEMA)


def _safe_parse_json(raw_output: str) -> dict:
    try:
        return json.loads(raw_output)
    except json.JSONDecodeError:
        if "```json" in raw_output:
            json_str = raw_output.split("```json", 1)[1].split("```", 1)[0]
            return json.loads(json_str)
        if "```" in raw_output:
            json_str = raw_output.split("```", 1)[1].split("```", 1)[0]
            return json.loads(json_str)
        raise


def _normalize_schema(parsed: dict) -> dict:
    normalized = _empty_schema()
    for key, value in parsed.items():
        normalized[key] = value
    return normalized


def extract_sla_with_llm(contract_text: str) -> dict:
    """Extract SLA details using a LangChain ChatOpenAI pipeline."""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return _empty_schema()

    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM_PROMPT),
            (
                "human",
                """
Extract the following SLA details from this car lease or loan contract.

Return JSON with these keys ONLY:
{schema_keys}

Contract text:
"""
{contract_text}
"""
""".strip(),
            ),
        ]
    )

    llm = ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0,
        api_key=api_key,
    )

    chain = prompt | llm

    try:
        result = chain.invoke(
            {
                "schema_keys": list(SLA_SCHEMA.keys()),
                "contract_text": contract_text[:6000],
            }
        )
        raw_output = (result.content or "").strip()
        parsed = _safe_parse_json(raw_output)
        if not isinstance(parsed, dict):
            raise ValueError("LLM returned non-dict JSON")
        return _normalize_schema(parsed)
    except Exception as e:
        print(f"LangChain LLM extraction failed: {e}")
        return _empty_schema()