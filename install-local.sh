# Get optional version argument
VERSION_ARG="$1"

if [ -n "$VERSION_ARG" ]; then
  echo "📦 Installing with version: $VERSION_ARG"
else
  echo "📦 Installing without version argument"
fi
echo ""

echo "🔑 install member"
cd member
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""

echo "🖨️ install content"
cd content
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""


echo "🗞️ install timeline"
cd timeline
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""


echo "📊 install activity"
cd activity
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""


echo "👨🏽‍🎨🖼 install image"
cd image
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""


echo "🔎 install search"
cd search
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh
fi
cd ..
echo ""


echo "🚪 install frontend"
cd frontend
if [ -n "$VERSION_ARG" ]; then
  source install-local.sh "$VERSION_ARG"
else
  source install-local.sh
fi
cd ..
echo ""


echo "🖨️ install batch"
cd batch
if [ -n "$VERSION_ARG" ]; then
  source install-helm-local.sh "$VERSION_ARG"
else
  source install-helm-local.sh main
fi
cd ..
echo ""


echo "✏️ check -n dailyfeed"
k get all -n dailyfeed
