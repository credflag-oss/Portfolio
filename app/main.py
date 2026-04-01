from __future__ import annotations

from datetime import datetime, timezone
from typing import List

from fastapi import FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel, Field

app = FastAPI(title="Spending Tracker API")


class ReceiptCandidate(BaseModel):
    item_name: str
    category: str
    price: float
    purchased_at: datetime


class ReceiptCandidatesResponse(BaseModel):
    candidates: List[ReceiptCandidate]


class PurchaseBase(BaseModel):
    item_name: str = Field(..., min_length=1)
    category: str = Field(..., min_length=1)
    price: float = Field(..., ge=0)
    purchased_at: datetime
    rating: int | None = Field(default=None, ge=1, le=5)
    receipt_image_url: str | None = None


class PurchaseCreate(PurchaseBase):
    pass


class PurchaseUpdate(BaseModel):
    item_name: str | None = Field(default=None, min_length=1)
    category: str | None = Field(default=None, min_length=1)
    price: float | None = Field(default=None, ge=0)
    purchased_at: datetime | None = None
    rating: int | None = Field(default=None, ge=1, le=5)
    receipt_image_url: str | None = None


class Purchase(PurchaseBase):
    id: int
    created_at: datetime
    updated_at: datetime


class PurchaseStore:
    def __init__(self) -> None:
        self._items: list[Purchase] = []
        self._next_id = 1

    def list(self) -> list[Purchase]:
        return list(self._items)

    def get(self, purchase_id: int) -> Purchase | None:
        return next((item for item in self._items if item.id == purchase_id), None)

    def create(self, payload: PurchaseCreate) -> Purchase:
        now = datetime.now(timezone.utc)
        purchase = Purchase(
            id=self._next_id,
            created_at=now,
            updated_at=now,
            **payload.model_dump(),
        )
        self._items.append(purchase)
        self._next_id += 1
        return purchase

    def update(self, purchase_id: int, payload: PurchaseUpdate) -> Purchase:
        purchase = self.get(purchase_id)
        if purchase is None:
            raise KeyError
        update_data = payload.model_dump(exclude_unset=True)
        updated = purchase.model_copy(update=update_data)
        updated.updated_at = datetime.now(timezone.utc)
        self._items[self._items.index(purchase)] = updated
        return updated


store = PurchaseStore()


@app.post("/receipts", response_model=ReceiptCandidatesResponse)
async def extract_receipt_candidates(file: UploadFile = File(...)) -> ReceiptCandidatesResponse:
    """Stub endpoint for OCR extraction."""
    if not file.filename:
        raise HTTPException(status_code=400, detail="파일 이름이 필요합니다.")
    return ReceiptCandidatesResponse(candidates=[])


@app.post("/purchases", response_model=Purchase)
async def create_purchase(payload: PurchaseCreate) -> Purchase:
    return store.create(payload)


@app.get("/purchases", response_model=list[Purchase])
async def list_purchases() -> list[Purchase]:
    return store.list()


@app.get("/purchases/{purchase_id}", response_model=Purchase)
async def get_purchase(purchase_id: int) -> Purchase:
    purchase = store.get(purchase_id)
    if purchase is None:
        raise HTTPException(status_code=404, detail="구매 내역을 찾을 수 없습니다.")
    return purchase


@app.patch("/purchases/{purchase_id}", response_model=Purchase)
async def update_purchase(purchase_id: int, payload: PurchaseUpdate) -> Purchase:
    try:
        return store.update(purchase_id, payload)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="구매 내역을 찾을 수 없습니다.") from exc
