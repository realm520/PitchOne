#!/bin/bash
# FetchSerieAFixtures.sh
# 从 API-Football 获取意甲 2025 赛季比赛数据并缓存为 JSON
#
# 用法:
#   ./script/FetchSerieAFixtures.sh              # 使用缓存（如果存在）
#   FORCE_REFRESH=true ./script/FetchSerieAFixtures.sh  # 强制刷新
#
# 环境变量:
#   API_FOOTBALL_KEY - API 密钥（默认使用内置密钥）
#   FORCE_REFRESH    - 设置为 true 强制刷新缓存
#   CACHE_FILE       - 缓存文件路径（默认 data/serie_a_2025.json）

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CACHE_FILE="${CACHE_FILE:-$PROJECT_DIR/data/serie_a_2025.json}"
API_FOOTBALL_KEY="${API_FOOTBALL_KEY:-0c8f0fed5d3a24dece111cfcfff0fbac}"
FORCE_REFRESH="${FORCE_REFRESH:-false}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  意甲 2025 赛季比赛数据获取${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}错误: 需要安装 jq${NC}"
    echo "Ubuntu/Debian: sudo apt install jq"
    echo "macOS: brew install jq"
    exit 1
fi

# 检查缓存
if [ -f "$CACHE_FILE" ] && [ "$FORCE_REFRESH" != "true" ]; then
    FIXTURE_COUNT=$(jq '.totalFixtures' "$CACHE_FILE" 2>/dev/null || echo "0")
    FUTURE_COUNT=$(jq '.futureFixtures' "$CACHE_FILE" 2>/dev/null || echo "0")
    GENERATED_AT=$(jq -r '.generatedAt' "$CACHE_FILE" 2>/dev/null || echo "unknown")

    echo -e "${YELLOW}使用缓存数据${NC}"
    echo "  缓存文件: $CACHE_FILE"
    echo "  生成时间: $GENERATED_AT"
    echo "  总比赛数: $FIXTURE_COUNT"
    echo "  未来比赛: $FUTURE_COUNT"
    echo ""
    echo -e "${GREEN}提示: 设置 FORCE_REFRESH=true 强制刷新${NC}"
    exit 0
fi

echo "正在从 API-Football 获取数据..."

# 创建临时文件
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# 调用 API
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TEMP_FILE" \
    --request GET \
    --url 'https://v3.football.api-sports.io/fixtures?league=135&season=2025' \
    --header "x-rapidapi-host: v3.football.api-sports.io" \
    --header "x-rapidapi-key: $API_FOOTBALL_KEY")

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}API 请求失败: HTTP $HTTP_CODE${NC}"
    cat "$TEMP_FILE"
    exit 1
fi

# 检查 API 错误
ERRORS=$(jq '.errors | length' "$TEMP_FILE" 2>/dev/null || echo "0")
if [ "$ERRORS" != "0" ]; then
    echo -e "${RED}API 返回错误:${NC}"
    jq '.errors' "$TEMP_FILE"
    exit 1
fi

# 获取当前时间戳
NOW=$(date +%s)

# 球队缩写映射（使用 jq 对象）
TEAM_CODES='{
    "AC Milan": "MIL",
    "Inter": "INT",
    "Juventus": "JUV",
    "Napoli": "NAP",
    "AS Roma": "ROM",
    "Lazio": "LAZ",
    "Atalanta": "ATA",
    "Fiorentina": "FIO",
    "Bologna": "BOL",
    "Torino": "TOR",
    "Udinese": "UDI",
    "Sassuolo": "SAS",
    "Empoli": "EMP",
    "Cagliari": "CAG",
    "Verona": "VER",
    "Hellas Verona": "VER",
    "Lecce": "LEC",
    "Genoa": "GEN",
    "Monza": "MON",
    "Salernitana": "SAL",
    "Frosinone": "FRO",
    "Parma": "PAR",
    "Venezia": "VEN",
    "Como": "COM",
    "Spezia": "SPE",
    "Cremonese": "CRE",
    "Sampdoria": "SAM",
    "Pisa": "PIS",
    "Bari": "BAR",
    "Palermo": "PAL",
    "Catanzaro": "CTZ",
    "Modena": "MOD",
    "Reggiana": "REG",
    "Cittadella": "CIT",
    "Sudtirol": "SUD",
    "Cesena": "CES",
    "Mantova": "MAN",
    "Juve Stabia": "JST",
    "Brescia": "BRE",
    "Cosenza": "COS",
    "Carrarese": "CAR"
}'

# 处理数据：过滤未来比赛，生成 matchId
echo "正在处理数据..."

jq --argjson now "$NOW" --argjson teamCodes "$TEAM_CODES" '
# 辅助函数：获取球队缩写
def getTeamCode($name):
    ($teamCodes[$name] // ($name | gsub("[^a-zA-Z]"; "") | .[0:3] | ascii_upcase));

# 辅助函数：提取轮次数字
def getRound:
    if .league.round then
        (.league.round | capture("(?<n>[0-9]+)") | .n | tonumber) // 0
    else 0 end;

# 过滤并转换
{
    fixtures: [
        .response[]
        | select(.fixture.timestamp > $now)
        | select(.fixture.status.short != "FT")
        | select(.fixture.status.short != "AET")
        | select(.fixture.status.short != "PEN")
        | {
            fixtureId: .fixture.id,
            homeTeam: .teams.home.name,
            awayTeam: .teams.away.name,
            homeTeamCode: getTeamCode(.teams.home.name),
            awayTeamCode: getTeamCode(.teams.away.name),
            kickoffTime: .fixture.timestamp,
            round: getRound,
            status: .fixture.status.short,
            venue: .fixture.venue.name,
            matchIdWDL: ("SerieA_2025_R" + (getRound | tostring) + "_" + getTeamCode(.teams.home.name) + "_vs_" + getTeamCode(.teams.away.name) + "_WDL"),
            matchIdOU: ("SerieA_2025_R" + (getRound | tostring) + "_" + getTeamCode(.teams.home.name) + "_vs_" + getTeamCode(.teams.away.name) + "_OU")
        }
    ] | sort_by(.kickoffTime),
    metadata: {
        league: "Serie A",
        leagueId: 135,
        season: "2025",
        apiHost: "v3.football.api-sports.io"
    },
    generatedAt: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    totalFixtures: ([.response[] | select(.fixture.timestamp > $now) | select(.fixture.status.short != "FT")] | length),
    futureFixtures: ([.response[] | select(.fixture.timestamp > $now) | select(.fixture.status.short != "FT")] | length)
}
' "$TEMP_FILE" > "$CACHE_FILE"

# 输出统计
TOTAL=$(jq '.totalFixtures' "$CACHE_FILE")
FUTURE=$(jq '.futureFixtures' "$CACHE_FILE")

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  数据获取完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  缓存文件: $CACHE_FILE"
echo "  未来比赛: $FUTURE 场"
echo "  将创建: $((FUTURE * 2)) 个市场 (WDL + OU)"
echo ""

# 显示前 5 场比赛预览
echo "前 5 场比赛预览:"
jq -r '.fixtures[:5][] | "  \(.matchIdWDL) - \(.homeTeam) vs \(.awayTeam)"' "$CACHE_FILE"
echo ""
