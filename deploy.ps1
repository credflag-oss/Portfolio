# ===========================================
# deploy.ps1 - 전체 프로젝트 일괄 푸시 스크립트
# 사용법: .\deploy.ps1 -version "v0.2.0" -message "OCR 안정화 완료"
# ===========================================

param(
    [string]$version = "",
    [string]$message = ""
)

# 버전/메시지 입력 없으면 대화형으로 받기
if (-not $version) {
    $version = Read-Host "  버전 입력 (예: v0.2.0, 없으면 Enter)"
}
if (-not $message) {
    $message = Read-Host "  업데이트 내용 입력 (예: OCR 안정화, Firebase 연동 완료)"
}

$date = Get-Date -Format "yyyy-MM-dd"
$commitMsg = if ($version) { "$version : $message [$date]" } else { "$message [$date]" }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deploy 시작" -ForegroundColor Cyan
Write-Host "  커밋 메시지: $commitMsg" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$success = $true

# -------------------------------------------
# 1. 기프티모아
# -------------------------------------------
Write-Host "[1/3] 기프티모아 푸시 중..." -ForegroundColor Green
Set-Location "Z:\giftimoa\real"
git add .
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Write-Host "  → 변경사항 없음 (스킵)" -ForegroundColor DarkGray
} else {
    git push origin master
    if ($LASTEXITCODE -ne 0) { $success = $false; Write-Host "  → 푸시 실패!" -ForegroundColor Red }
    else { Write-Host "  → 완료 ✅" -ForegroundColor Green }
}

Write-Host ""

# -------------------------------------------
# 2. 주식 자동매매
# -------------------------------------------
Write-Host "[2/3] 주식 자동매매 백테스터 푸시 중..." -ForegroundColor Green
Set-Location "Z:\autotrader"
git add .
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Write-Host "  → 변경사항 없음 (스킵)" -ForegroundColor DarkGray
} else {
    git push origin master
    if ($LASTEXITCODE -ne 0) { $success = $false; Write-Host "  → 푸시 실패!" -ForegroundColor Red }
    else { Write-Host "  → 완료 ✅" -ForegroundColor Green }
}

Write-Host ""

# -------------------------------------------
# 3. 포트폴리오
# -------------------------------------------
Write-Host "[3/3] 포트폴리오 푸시 중..." -ForegroundColor Green
Set-Location "Z:\Portfolio"
git add .
git commit -m "portfolio: $commitMsg"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  → 변경사항 없음 (스킵)" -ForegroundColor DarkGray
} else {
    git push origin main
    if ($LASTEXITCODE -ne 0) { $success = $false; Write-Host "  → 푸시 실패!" -ForegroundColor Red }
    else { Write-Host "  → 완료 ✅" -ForegroundColor Green }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($success) {
    Write-Host "  전체 배포 완료! 🚀" -ForegroundColor Green
    Write-Host "  포트폴리오: https://credflag-oss.github.io/Portfolio/" -ForegroundColor Yellow
} else {
    Write-Host "  일부 실패가 있어요. 위 오류를 확인해주세요." -ForegroundColor Red
}
Write-Host "==========================================" -ForegroundColor Cyan
