import sqlite3
import os
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "database.db")


# ---------------- CONNECTION ---------------- #

def get_connection():
    return sqlite3.connect(DB_PATH)


# ---------------- CONTRACT TABLE ---------------- #

def create_contracts_table():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS contracts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_name TEXT NOT NULL,
            raw_text TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Backward-compatible migration for existing DBs created before `created_at`.
    cursor.execute("PRAGMA table_info(contracts)")
    columns = [row[1] for row in cursor.fetchall()]
    if "created_at" not in columns:
        cursor.execute("ALTER TABLE contracts ADD COLUMN created_at TIMESTAMP")
        cursor.execute(
            "UPDATE contracts SET created_at = datetime('now') WHERE created_at IS NULL"
        )

    conn.commit()
    conn.close()


def save_contract(file_name: str, raw_text: str) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO contracts (file_name, raw_text) VALUES (?, ?)",
        (file_name, raw_text)
    )
    contract_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return contract_id


# ---------------- SLA TABLE ---------------- #

def create_sla_table():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sla_extractions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            contract_id INTEGER NOT NULL,
            sla_json TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (contract_id) REFERENCES contracts(id)
        )
    """)
    conn.commit()
    conn.close()


def save_sla(contract_id: int, sla_data: dict):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO sla_extractions (contract_id, sla_json) VALUES (?, ?)",
        (contract_id, json.dumps(sla_data))
    )
    conn.commit()
    conn.close()


def get_contract_by_id(contract_id: int) -> dict:
    """Get a contract by its ID."""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, file_name, raw_text, created_at FROM contracts WHERE id = ?",
        (contract_id,)
    )
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return {
            "id": row[0],
            "file_name": row[1],
            "raw_text": row[2],
            "created_at": row[3]
        }
    return None


def get_sla_by_contract_id(contract_id: int) -> dict:
    """Get SLA extraction for a contract."""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT sla_json FROM sla_extractions WHERE contract_id = ?",
        (contract_id,)
    )
    row = cursor.fetchone()
    conn.close()
    
    if row and row[0]:
        return json.loads(row[0])
    return None


def get_all_contracts() -> list:
    """Get all contracts from database."""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, file_name, created_at FROM contracts ORDER BY created_at DESC"
    )
    rows = cursor.fetchall()
    conn.close()
    
    return [
        {"id": row[0], "file_name": row[1], "created_at": row[2]}
        for row in rows
    ]


def delete_contract(contract_id: int) -> bool:
    """Delete a contract and its SLA extraction."""
    conn = get_connection()
    cursor = conn.cursor()
    
    # Delete SLA first
    cursor.execute("DELETE FROM sla_extractions WHERE contract_id = ?", (contract_id,))
    # Delete contract
    cursor.execute("DELETE FROM contracts WHERE id = ?", (contract_id,))
    
    deleted = cursor.rowcount > 0
    conn.commit()
    conn.close()
    
    return deleted
