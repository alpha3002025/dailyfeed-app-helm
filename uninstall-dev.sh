echo "🔑 uninstall member"
cd member
helm uninstall -n dailyfeed dailyfeed-member
cd ..
echo ""

echo "🖨️ uninstall content"
cd content
helm uninstall -n dailyfeed dailyfeed-content
cd ..
echo ""


echo "🗞️ uninstall timeline"
cd timeline
helm uninstall -n dailyfeed dailyfeed-timeline
cd ..
echo ""


echo "📊 uninstall activity"
cd activity
helm uninstall -n dailyfeed dailyfeed-activity
cd ..
echo ""


echo "👨🏽‍🎨🖼 uninstall image"
cd image
helm uninstall -n dailyfeed dailyfeed-image
cd ..
echo ""


echo "🔎 uninstall search"
cd search
helm uninstall -n dailyfeed dailyfeed-search
cd ..
echo ""


echo "🚪 uninstall frontend"
cd frontend/k8s
kubectl delete -f .
cd ../..
echo ""


echo "⚙️ uninstall debug svc"
kubectl delete svc -n dailyfeed dailyfeed-member-debug-svc
echo ""


echo "✏️ check -n dailyfeed"
kubectl get all -n dailyfeed
echo ""

