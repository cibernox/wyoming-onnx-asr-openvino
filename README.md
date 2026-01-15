# Wyoming Onnx ASR

[Wyoming protocol](https://github.com/rhasspy/wyoming) server for the [onnx-asr](https://github.com/istupakov/onnx-asr/) speech to text system.

## Docker Image

```shell
docker run -it -p 10300:10300 -v /path/to/local/data:/data ghcr.io/tboby/wyoming-onnx-asr
```

or for gpu

```shell
docker run -it -p 10300:10300 --gpus all -v /path/to/local/data:/data ghcr.io/tboby/wyoming-onnx-asr-gpu
```

or for Intel iGPU with OpenVINO

```shell
docker run -it -p 10300:10300 --device /dev/dri:/dev/dri -v /path/to/local/data:/data -v /path/to/cache:/cache ghcr.io/tboby/wyoming-onnx-asr-openvino
```

There is also gpu TensorRT support, but it's a huge image and doesn't seem to make much performance difference.
You might want to mount in a cache folder if using it (`/cache`).

## Local Install

Install [uv](https://docs.astral.sh/uv/)

Clone the repository and use `uv`:

``` sh
git clone https://github.com/tboby/wyoming-onnx-asr.git
cd wyoming-onnx-asr
uv sync
```

Run a server anyone can connect to:

```sh
uv run --uri 'tcp://0.0.0.0:10300'
```

For OpenVINO with Intel iGPU:

```sh
uv sync --extra openvino
uv run --device openvino-gpu --uri 'tcp://0.0.0.0:10300'
```

For OpenVINO with CPU:

```sh
uv sync --extra openvino
uv run --device openvino-cpu --uri 'tcp://0.0.0.0:10300'
```

The `--model-en` or `--model-multilingual` can also be a HuggingFace model but see [onnx-asr](https://github.com/istupakov/onnx-asr?tab=readme-ov-file#supported-model-names) for details

**NOTE**: Models are downloaded temporarily to the `HF_HUB_CACHE` directory, which defaults to `~/.cache/huggingface/hub`.
You may need to adjust this environment variable when using a read-only root filesystem (e.g., `HF_HUB_CACHE=/tmp`).

## Configuration

- Quantization: the parakeet model supports int8, but make sure to compare as performance may or may not improve.

### OpenVINO Support

This project includes support for Intel hardware acceleration through OpenVINO, which can significantly improve performance on Intel CPUs and integrated GPUs.

#### Device Options

- `--device openvino-cpu`: Use OpenVINO CPU execution provider (optimized for Intel CPUs)
- `--device openvino-gpu`: Use OpenVINO GPU execution provider (for Intel integrated GPUs)

#### Requirements for Intel GPU Support

- Intel GPU with Gen9 or later (6th generation Core processors or newer)
- Intel GPU drivers installed
- For Docker: The `/dev/dri` device must be mounted

#### Docker Compose Examples

For Intel iGPU:
```yaml
# Using compose.openvino.yaml
docker compose -f compose.openvino.yaml up
```

For CPU-only OpenVINO:
```yaml
# Using compose.openvino-cpu.yaml
docker compose -f compose.openvino-cpu.yaml up
```

#### Environment Variables

- `OV_CACHE_DIR`: Directory for OpenVINO model cache (default: `/cache/openvino`)
- `OV_ENABLE_DEVICE_CACHE`: Enable OpenVINO device caching for faster startup (default: `1`)

#### Performance Notes

- Intel iGPU (openvino-gpu): Typically 2-4x faster than CPU, with lower power consumption than discrete GPUs
- Intel CPU (openvino-cpu): Optimized Intel CPU execution, often faster than standard CPU provider
- Model caching: First run will be slower due to model compilation, subsequent runs will be faster

## Running tooling
Install [mise](https://mise.jdx.dev/) and use `mise run` to get a list of tasks to test, format, lint, run.