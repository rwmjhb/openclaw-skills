#!/bin/bash
# 批量录入功能 API 测试脚本
# 测试流程: 创建批量任务 → 上传3张成分表图片 → 标记就绪 → 查看分析状态

set -e

API_BASE="http://localhost:4001"
# 从模拟器 UserDefaults 提取 token
PLIST="/Users/pope/Library/Developer/CoreSimulator/Devices/E083B1B9-B6EB-4B1E-9B06-59555984D97E/data/Containers/Data/Application/A2B9D6FB-AED8-4FDC-95CD-B172077E7B5D/Library/Preferences/com.skinguardian.app.plist"
TOKEN=$(plutil -p "$PLIST" 2>/dev/null | python3 -c "
import sys, json, re
text = sys.stdin.read()
match = re.search(r'\"flutter\.sb-.*?auth-token\" => \"(.+?)\"$', text, re.MULTILINE | re.DOTALL)
if match:
    data = json.loads(match.group(1))
    print(data['access_token'])
")

if [ -z "$TOKEN" ]; then
  echo "❌ 无法获取 auth token"
  exit 1
fi
echo "✅ Auth token 获取成功 (前20字符: ${TOKEN:0:20}...)"

# 测试图片路径 (3张不同产品的成分表)
DCIM="/Users/pope/Library/Developer/CoreSimulator/Devices/E083B1B9-B6EB-4B1E-9B06-59555984D97E/data/Media/DCIM/100APPLE"
IMG1="$DCIM/IMG_0013.JPG"  # Charlotte Tilbury 精油成分表
IMG2="$DCIM/IMG_0015.JPG"  # 中文护肤品成分表
IMG3="$DCIM/IMG_0019.JPG"  # 诗维蓝黛角鲨烷精油成分表

echo ""
echo "📸 测试图片:"
echo "  1. $(basename $IMG1) - Charlotte Tilbury 精油"
echo "  2. $(basename $IMG2) - 中文护肤品"
echo "  3. $(basename $IMG3) - 诗维蓝黛角鲨烷精油"

# 检查图片文件
for img in "$IMG1" "$IMG2" "$IMG3"; do
  if [ ! -f "$img" ]; then
    echo "❌ 图片不存在: $img"
    exit 1
  fi
done
echo "✅ 所有图片文件存在"

# ============================================
# Step 1: 检查是否有活跃的批量任务
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 1: 检查活跃批量任务..."
ACTIVE=$(curl -s "$API_BASE/api/v1/ingredients/batch/active" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")
echo "  响应: $ACTIVE"

IS_ACTIVE=$(echo "$ACTIVE" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('active', False))" 2>/dev/null)
if [ "$IS_ACTIVE" = "True" ]; then
  ACTIVE_BATCH_ID=$(echo "$ACTIVE" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('batchId', ''))" 2>/dev/null)
  echo "  ⚠️  发现活跃批量任务: $ACTIVE_BATCH_ID，先取消..."
  curl -s -X DELETE "$API_BASE/api/v1/ingredients/batch/$ACTIVE_BATCH_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json"
  echo "  ✅ 已取消"
fi

# ============================================
# Step 2: 创建批量任务 (3个产品)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🆕 Step 2: 创建批量任务 (3个产品)..."
CREATE_RESP=$(curl -s -X POST "$API_BASE/api/v1/ingredients/batch/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"totalItems": 3}')
echo "  响应: $CREATE_RESP"

BATCH_ID=$(echo "$CREATE_RESP" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('batchId', ''))" 2>/dev/null)
if [ -z "$BATCH_ID" ]; then
  echo "❌ 创建失败，无 batchId"
  echo "  完整响应: $CREATE_RESP"
  exit 1
fi
echo "  ✅ 批量任务创建成功: $BATCH_ID"

# ============================================
# Step 3: 依次上传3张图片并标记就绪
# ============================================
IMAGES=("$IMG1" "$IMG2" "$IMG3")
NAMES=("Charlotte Tilbury 精油" "中文护肤品" "诗维蓝黛角鲨烷精油")

for i in 0 1 2; do
  SEQ=$((i + 1))
  IMG="${IMAGES[$i]}"
  NAME="${NAMES[$i]}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📤 Step 3.$SEQ: 上传产品 $SEQ - $NAME"

  # 3a. 上传图片到存储
  STORAGE_PATH="batch/$BATCH_ID/$SEQ/ingredients-1.jpeg"
  echo "  上传到: $STORAGE_PATH"

  UPLOAD_RESP=$(curl -s -X POST "$API_BASE/api/v1/storage/upload" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$IMG" \
    -F "path=$STORAGE_PATH")
  echo "  上传响应: $UPLOAD_RESP"

  UPLOADED_PATH=$(echo "$UPLOAD_RESP" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('path', d.get('storagePath', '')))" 2>/dev/null)
  if [ -z "$UPLOADED_PATH" ]; then
    UPLOADED_PATH="$STORAGE_PATH"
  fi
  echo "  ✅ 图片上传成功: $UPLOADED_PATH"

  # 3b. 标记产品就绪
  echo "  标记产品 $SEQ 就绪..."
  READY_RESP=$(curl -s -X POST "$API_BASE/api/v1/ingredients/batch/$BATCH_ID/items/$SEQ/ready" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"images\": [{\"path\": \"$UPLOADED_PATH\", \"label\": \"ingredients\", \"sequence\": 1}]}")
  echo "  就绪响应: $READY_RESP"
  echo "  ✅ 产品 $SEQ 已标记就绪"
done

# ============================================
# Step 4: 查看批量任务状态
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 4: 查看批量任务状态..."
STATUS_RESP=$(curl -s "$API_BASE/api/v1/ingredients/batch/$BATCH_ID/status" \
  -H "Authorization: Bearer $TOKEN")
echo "  状态响应: $(echo "$STATUS_RESP" | python3 -c "import json,sys; print(json.dumps(json.loads(sys.stdin.read()), indent=2, ensure_ascii=False))" 2>/dev/null | head -30)"

# ============================================
# Step 5: 等待分析完成 (轮询)
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Step 5: 等待分析完成 (最多60秒)..."
for attempt in $(seq 1 12); do
  sleep 5
  STATUS_RESP=$(curl -s "$API_BASE/api/v1/ingredients/batch/$BATCH_ID/status" \
    -H "Authorization: Bearer $TOKEN")
  
  BATCH_STATUS=$(echo "$STATUS_RESP" | python3 -c "
import json,sys
data = json.loads(sys.stdin.read())
status = data.get('status', 'unknown')
items = data.get('items', [])
completed = sum(1 for i in items if i.get('status') == 'completed')
failed = sum(1 for i in items if i.get('status') == 'failed')
pending = sum(1 for i in items if i.get('status') in ('pending', 'processing'))
print(f'{status}|{completed}|{failed}|{pending}|{len(items)}')
" 2>/dev/null)
  
  IFS='|' read -r BSTATUS COMPLETED FAILED PENDING TOTAL <<< "$BATCH_STATUS"
  echo "  [$attempt/12] 状态: $BSTATUS | 完成: $COMPLETED | 失败: $FAILED | 处理中: $PENDING / $TOTAL"
  
  if [ "$PENDING" = "0" ] || [ "$BSTATUS" = "completed" ] || [ "$BSTATUS" = "failed" ]; then
    break
  fi
done

# ============================================
# Step 6: 输出最终结果
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 最终结果:"
FINAL_STATUS=$(curl -s "$API_BASE/api/v1/ingredients/batch/$BATCH_ID/status" \
  -H "Authorization: Bearer $TOKEN")

echo "$FINAL_STATUS" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(f'  批量ID: {data.get(\"batchId\", \"?\")}'  )
print(f'  总状态: {data.get(\"status\", \"?\")}'  )
items = data.get('items', [])
for item in items:
    seq = item.get('sequence', '?')
    status = item.get('status', '?')
    product_name = ''
    result = item.get('result', {})
    if result:
        product_name = result.get('productName', result.get('product_name', ''))
    print(f'  产品 {seq}: {status}' + (f' → {product_name}' if product_name else ''))
" 2>/dev/null

echo ""
echo "✅ 测试完成！"
echo "  Batch ID: $BATCH_ID"
