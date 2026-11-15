#pragma once
#if defined(_WIN32)
#include <windows.h>
#include <wincodec.h>
#include <cstdint>
#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "ole32.lib")

// WIC codecs are optional on Windows. Return 0 when the platform lacks one.
static int nf_origin_wic_webp(const uint8_t *input, int inputSize, int *dimensions, uint8_t *output, int outputSize)
{
  if (!input || inputSize <= 0 || !dimensions) return 0;
  const HRESULT initialized = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  const bool uninitialize = initialized == S_OK || initialized == S_FALSE;
  if (FAILED(initialized) && initialized != RPC_E_CHANGED_MODE) return 0;
  IWICImagingFactory *factory = nullptr;
  IWICStream *stream = nullptr;
  IWICBitmapDecoder *decoder = nullptr;
  IWICBitmapFrameDecode *frame = nullptr;
  IWICFormatConverter *converter = nullptr;
  UINT width = 0, height = 0;
  int result = 0;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&factory));
  if (SUCCEEDED(hr)) hr = factory->CreateStream(&stream);
  if (SUCCEEDED(hr)) hr = stream->InitializeFromMemory(const_cast<BYTE *>(input), static_cast<DWORD>(inputSize));
  if (SUCCEEDED(hr)) hr = factory->CreateDecoderFromStream(stream, nullptr, WICDecodeMetadataCacheOnLoad, &decoder);
  if (SUCCEEDED(hr)) hr = decoder->GetFrame(0, &frame);
  if (SUCCEEDED(hr)) hr = frame->GetSize(&width, &height);
  if (SUCCEEDED(hr) && (width == 0 || height == 0 || width > 4096 || height > 4096 ||
                        static_cast<uint64_t>(width) * height > 16777216)) hr = E_INVALIDARG;
  if (SUCCEEDED(hr))
  {
    dimensions[0] = static_cast<int>(width);
    dimensions[1] = static_cast<int>(height);
    if (!output) result = 1;
    else if (outputSize >= 0 && static_cast<uint64_t>(outputSize) >= static_cast<uint64_t>(width) * height * 4)
    {
      hr = factory->CreateFormatConverter(&converter);
      if (SUCCEEDED(hr)) hr = converter->Initialize(frame, GUID_WICPixelFormat32bppRGBA,
        WICBitmapDitherTypeNone, nullptr, 0.0, WICBitmapPaletteTypeCustom);
      if (SUCCEEDED(hr)) hr = converter->CopyPixels(nullptr, width * 4, outputSize, output);
      if (SUCCEEDED(hr)) result = 1;
    }
  }
  if (converter) converter->Release();
  if (frame) frame->Release();
  if (decoder) decoder->Release();
  if (stream) stream->Release();
  if (factory) factory->Release();
  if (uninitialize) CoUninitialize();
  return result;
}
#endif
