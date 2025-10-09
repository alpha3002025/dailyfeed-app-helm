echo "🔑 install member"
cd member
source install-helm-local.sh
cd ..
echo ""

echo "🖨️ install content"
cd content
source install-helm-local.sh
cd ..
echo ""


echo "🗞️ install timeline"
cd timeline
source install-helm-local.sh
cd ..
echo ""


echo "📊 install activity"
cd activity
source install-helm-local.sh
cd ..
echo ""


echo "👨🏽‍🎨🖼 install image"
cd image
source install-helm-local.sh
cd ..
echo ""


echo "🔎 install search"
cd search
source install-helm-local.sh
cd ..
echo ""


echo "🚪 install frontend"
cd frontend
source install-local.sh
cd ..
echo ""


echo "✏️ check -n dailyfeed"
k get all -n dailyfeed
