import 'dart:js_interop';

@JS('toggleGrubasekTorch')
external JSPromise<JSBoolean>? _toggleGrubasekTorch(JSBoolean enable);

/// Tries to toggle the hardware LED torch on browsers supporting MediaTrackConstraints.torch.
Future<bool> tryToggleWebHardwareTorch(bool enable) async {
  try {
    final promise = _toggleGrubasekTorch(enable.toJS);
    if (promise != null) {
      final result = await promise.toDart;
      return result.toDart;
    }
  } catch (_) {}
  return false;
}
