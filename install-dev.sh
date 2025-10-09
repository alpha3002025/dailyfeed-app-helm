echo "🔑 install member"
cd member
source install-helm-dev.sh
cd ..
echo ""

echo "🖨️ install content"
cd content
source install-helm-dev.sh
cd ..
echo ""


echo "🗞️ install timeline"
cd timeline
source install-helm-dev.sh
cd ..
echo ""


echo "📊 install activity"
cd activity
source install-helm-dev.sh
cd ..
echo ""


echo "👨🏽‍🎨 install image"
cd image
source install-helm-dev.sh
cd ..
echo ""


echo "🔎 install search"
cd search
source install-helm-dev.sh
cd ..
echo ""