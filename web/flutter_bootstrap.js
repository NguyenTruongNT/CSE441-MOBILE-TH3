{{flutter_js}}
{{flutter_build_config}}

// Use the CanvasKit files included by Flutter, including behind restricted networks.
const showStartupError = () => {
  const status = document.getElementById('startup-status');
  if (status) status.textContent = 'Chưa mở được ứng dụng. Kiểm tra kết nối rồi tải lại trang.';
};

_flutter.loader.load({
  config: {canvasKitBaseUrl: 'canvaskit/'},
  onEntrypointLoaded: async (engineInitializer) => {
    try {
      const app = await engineInitializer.initializeEngine();
      await app.runApp();
      document.getElementById('startup-status')?.remove();
    } catch (error) {
      showStartupError();
      console.error(error);
    }
  },
}).catch(showStartupError);
