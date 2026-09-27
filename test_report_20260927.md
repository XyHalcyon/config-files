# DeepSeek V4 Flash 混合序列压测报告

> 报告编号: 20260927-03
> 测试日期: 2026-09-27
> 测试环境: syn-113 (8 × Ascend 910B3, CANN 9.0.1, vLLM-Ascend)

---

## 1. 服务端配置

### 1.1 NPU RDMA 通信配置（run_dp_template.sh）

| 配置项 | 值 | 说明 |
|---|---|---|
| `MF_NPU_RDMA_SEND_CQ_DEPTH` | **8192** | RDMA 发送完成队列深度 |
| `MF_NPU_RDMA_RECV_CQ_DEPTH` | **128** | RDMA 接收完成队列深度 |
| `MF_NPU_RDMA_MAX_SEND_WR` | **8192** | RDMA 最大发送工作请求数 |
| `MF_NPU_RDMA_MAX_RECV_WR` | **128** | RDMA 最大接收工作请求数 |

### 1.2 vLLM 启动参数（核心）

| 参数 | 值 | 说明 |
|---|---|---|
| `--max_model_len` | **1048576** | 模型最大上下文长度 1M token |
| `--max-num-batched-tokens` | **12288** | 单批最大 prefill token 数 12K |
| `--max-num-seqs` | **32** | 单实例最大并发序列数 32 |
| `--gpu-memory-utilization` | 0.945 | GPU 显存利用率 94.5% |
| `--tensor-parallel-size` | 8 | 8 卡张量并行 |
| `--block-size` | 32 | KV cache 块大小 32 token |
| `--quantization` | ascend | 昇腾量化 |
| `--enforce-eager` | - | 强制 eager 模式（禁图编译） |
| `--async-scheduling` | - | 异步调度 |
| `--enable-chunked-prefill` | - | 分块 prefill |
| `--enable-prefix-caching` | - | 前缀缓存 |
| `--no-disable-hybrid-kv-cache-manager` | - | 混合 KV cache 管理器 |

### 1.3 PD 分离架构配置（kv-transfer-config）

```json
{
  "kv_connector": "MultiConnector",
  "kv_role": "kv_producer",
  "connectors": [
    {
      "kv_connector": "MooncakeHybridConnector",
      "prefill": {"dp_size": 1, "tp_size": 8},   // prefill: 1 DP × 8 TP
      "decode":  {"dp_size": 8, "tp_size": 1}     // decode: 8 DP × 1 TP
    },
    {
      "kv_connector": "AscendStoreConnector",
      "backend": "memcache"
    }
  ]
}
```

| 阶段 | DP | TP | 说明 |
|---|---|---|---|
| Prefill | 1 | 8 | 1 数据并行 × 8 张量并行（单实例 8 卡并行 prefill） |
| Decode | 8 | 1 | 8 数据并行 × 1 张量并行（8 实例各 1 卡 decode） |

---

## 2. 客户端测试配置

### 2.1 run_mmc_config.sh 配置

| 配置项 | 值 | 说明 |
|---|---|---|
| `--url` | `http://71.10.29.112:1999/v1/chat/completions` | 负载均衡代理地址 |
| `--model` | `dsv4` | 目标模型 |
| `--api` | `openai` | API 协议 |
| `--no-test-connection` | - | 跳过连接预测试 |
| `--dataset` | `line_by_line` | 逐行读取数据集 |
| `--dataset-path` | `gsm8k_4k_12k_c128_cache25_...jsonl` | 混合序列数据集（20 档长度, cache 25%） |
| `--apply-chat-template` | - | 应用 chat 模板 |
| `--max-prompt-length` | 999999 | 最大 prompt 长度上限 |
| `-n` | 100000 | 总请求数上限 |
| `--rate` | 10 | 发送速率 10 req/s |
| `--parallel` | 100 | 并发数 100 |
| `--max-tokens` | 2048 | 单请求最大生成 token 数 |
| `--warmup-num` | 120 | 预热请求数 |
| `--duration` | 3600 | 时长上限 1 小时 |
| `--seed` | 42 | 随机种子 |
| `--stream` | - | 流式输出 |
| `--temperature` | 0.0 | 贪心解码 |
| `--connect-timeout` | 60 | 连接超时 60s |
| `--read-timeout` | 300 | 读超时 300s |
| `--total-timeout` | 600 | 单请求总超时 600s |
| `--outputs-dir` | `outputs/mmc_test_8k_8k_03` | 输出目录 |
| `--name` | `8k_8k_14k_290` | 测试名称 |

### 2.2 实际生效的结束条件

| 参数 | 值 | 是否先到 |
|---|---|---|
| `--duration` | 3600s（1 小时） | **先到** |
| `-n` | 100000 | 未到（实际 35941 条） |
| `--rate` | 10 req/s | 实际有效 RPS 0.81（因服务端处理慢） |

> 注：`--rate 10` 意味着理论上 1 小时可发 36000 条，与 `-n 100000` 无关。实际只发 35941 条（因 `--duration 3600` 先到），服务端崩溃后大量失败。

---

## 3. 执行日志分析

### 3.1 服务端日志：serve_20260927030453.log

| 项目 | 内容 |
|---|---|
| 服务启动时间 | 2026-09-27 03:05:02 |
| 服务崩溃退出时间 | 2026-09-27 06:20:56 |
| 服务运行时长 | **约 3.25 小时** |
| 错误总数 | 66791 条 ERROR |
| 是否有 vector core timeout (507034) | **无** |
| 最终退出原因 | `EngineDeadError` → `TBE Subprocess: main process disappeared` × 8 |

#### 3.1.1 启动期 WARN（无害）

```
03:11:49 WARN [HYBM] Hccp Init RA failed: 328002 devid:0-7     // 8 卡 RA 子模块初始化失败
03:11:52 WARN [HYBM] Failed to alloc 85899345920 (80GB) with hugepage via mmap, error: 12
03:11:52 WARN [HYBM] Trying halMemAlloc for DRAM hugepage allocation.   // 自动回退 DRAM
```

8 卡 RA 初始化失败 + hugepage 不足 80GB 回退 DRAM，主流程不受影响（服务运行了 3.25 小时）。

#### 3.1.2 运行期崩溃：HYBM RDMA 通信层故障（error 328100）

**错误分两波爆发，中间有恢复**：

| 时间 | 错误数 | 事件 |
|---|---|---|
| 03:05 ~ 05:57 | 0 | 服务正常运行约 2.85 小时 |
| 05:57:29 | **18028** | **第 1 波爆发**：`RaSendWr failed: 32` → `ReadRemoteAsync failed: 328100` |
| 05:58 ~ 06:03 | 0 | **服务部分恢复**，吞吐正常（5000~13000 tokens/s） |
| 06:04:02 | **47203** | **第 2 波爆发**（更猛烈）：同样的 328100 错误链 |
| 06:12 | 3231 | 第 3 波（较小） |
| 06:20:56 | - | `EngineDeadError` → 服务退出 |

#### 3.1.3 错误因果链

```
[根因·通信层]  DlHccpApi::RaSendWr(handle, &wr, &opRsp) failed: 32
      ↓ HccpApi 返回 32（通信操作失败）
[驱动层·HYBM]  ReadRemoteAsync() failed: 328100
              → Failed to ReadRemoteAsync by device transport
              → send notify wr failed: 328100
              → Failed to WriteRemote
      ↓ 跨设备 RDMA 数据拷贝失败
[数据层]       BatchCopyRead: Failed to read src to dest
              BatchDataCopy: data batch copy failed: -1 src:X dest:Y
              BatchCopyData: Data copy failed, ret: -1
      ↓ KV cache 跨 TP worker 同步失败
[缓存层·MMC]   WaitFeatures batch key from X to Y failed
      ↓
[框架层·vLLM]  EngineDeadError: EngineCore encountered an issue
      ↓ TBE Subprocess: main process disappeared × 8
[进程层]       服务退出，遗留 248 leaked semaphores + 10 leaked shared_memory
```

#### 3.1.4 关键错误日志（原始）

**第 1 波（05:57:29）**：
```
2026-09-27 05:57:29.961411 ERROR [148883-154537][HYBM device_rdma_transport_manager.cpp:767 RemoteIO] DlHccpApi::RaSendWr(handle, &wr, &opRsp) failed: 328100
2026-09-27 05:57:29.961481 ERROR [148883-154537][HYBM device_rdma_transport_manager.cpp:437 ReadRemoteAsync] ReadRemoteAsync() failed: 328100
2026-09-27 05:57:29.961493 ERROR [148883-154537][HYBM compose_transport_manager.cpp:440 ReadRemoteAsync] Failed to ReadRemoteAsync by device transport ret:328100
2026-09-27 05:57:29.961501 ERROR [148883-154537][HYBM compose_transport_manager.cpp:453 ReadRemoteAsync] Failed to ReadRemote.
2026-09-27 05:57:29.961511 ERROR [148883-154537][HYBM device_rdma_transport_manager.cpp:1017 Synchronize] send notify wr failed: 328100
2026-09-27 05:57:29.961519 ERROR [148883-154537][HYBM compose_transport_manager.cpp:527 Synchronize] Failed to ReadRemoteAsync by device transport ret:328100
2026-09-27 05:57:29.961527 ERROR [148883-154537][HYBM compose_transport_manager.cpp:538 Synchronize] Failed to WriteRemote.
2026-09-27 05:57:29.961538 ERROR [148883-154537][HYBM hybm_data_op_device_rdma.cpp:928 BatchCopyRead] Failed to read src to dest
2026-09-27 05:57:29.961547 ERROR [148883-154537][HYBM hybm_compose_data_op.cpp:169 BatchDataCopy] data batch copy failed: -1 src:7 dest: 54
2026-09-27 05:57:29.961558 ERROR [148883-154537][HYBM hybm_entity_default.cpp:830 BatchCopyData] Data copy failed, ret: -1
2026-09-27 05:57:29.962414 ERROR [148883-148883][MMC mmc_client_default.cpp:659 WaitFeatures] batch key from 1360 to 1361 failed, error code -1
```

**最终退出（06:20:56）**：
```
(APIServer pid=148526) ERROR 09-27 06:20:56 [async_llm.py:704] Traceback (most recent call last):
  File "/vllm-workspace/vllm/vllm/v1/engine/async_llm.py", line 660, in output_handler
    outputs = await engine_core.get_output_async()
  File "/vllm-workspace/vllm/vllm/v1/engine/core_client.py", line 1061, in get_output_async
    raise self._format_exception(outputs) from None
vllm.v1.engine.exceptions.EngineDeadError: EngineCore encountered an issue. See stack trace (above) for the root cause.

[ERROR] TBE Subprocess[task_distribute] raise error[], main process disappeared!  × 11
UserWarning: resource_tracker: There appear to be 248 leaked semaphore objects to clean up at shutdown
UserWarning: resource_tracker: There appear to be 10 leaked shared_memory objects to clean up at shutdown
```

#### 3.1.5 根因分析

**根因：HYBM RDMA 跨设备通信层故障（error 328100，`RaSendWr failed: 32`），运行 2.85 小时后突发性间歇性通信故障。**

本次错误有"出错→恢复 6 分钟→再爆发"特征，说明是间歇性通信抖动而非永久性硬件故障。

---

### 3.2 客户端测试日志：mmc_config_8k_8k_14k_290_100_parallel_10_rate_03_20260927054605.log

| 项目 | 内容 |
|---|---|
| 测试启动时间 | 2026-09-27 05:46:20 |
| 测试结束时间 | 2026-09-27 06:46:36 |
| 测试时长 | 1 小时（duration 3600s 正常结束） |
| 错误总数 | 7915 条（含 2511 `ConnectionResetError` + 6 `BrokenPipeError`） |
| 错误爆发时段 | 集中在 06:04~06:06（对应服务端第 2 波崩溃） |

#### 3.2.1 客户端错误时间分布

| 时间 | 错误数 | 对应服务端事件 |
|---|---|---|
| 06:04 | 399 | 服务端第 2 波爆发 |
| 06:05 | 1405 | 服务端持续崩溃 |
| 06:06 | 878 | 服务端持续崩溃 |
| 06:07~06:44 | 零星 1~2 | 残余超时 |

> 客户端错误集中在 06:04~06:06，与服务端第 2 波 RDMA 故障爆发时间精确对应。

---

## 4. 测试结果分析

### 4.1 测试结果总览（performance_summary.txt）

| 指标 | 值 | 说明 |
|---|---|---|
| **并发数** | 100 | `--parallel 100` |
| **速率** | 10 req/s | `--rate 10` |
| **总请求数** | 35941 | 受 `--duration 3600` 限制 |
| **实际 RPS** | 0.81 req/s | **远低于 10 req/s**（服务端处理慢） |
| **生成速率** | 201.24 tok/s | 输出 token 吞吐 |
| **成功率** | **8.2%** | **极低**（33008/35941 失败） |
| **测试时长** | 3600.02 s | 1 小时（duration 正常结束） |
| **总生成 token** | 724,482 | 约 72 万 token |

### 4.2 请求成功/失败统计

| 项目 | 数量 | 占比 |
|---|---|---|
| 总请求 | 35941 | 100% |
| 成功请求 | **2933** | **8.2%** |
| 失败请求 | **33008** | **91.8%** |
| 流式请求 | 35941 | 100% |

> **失败率 91.8% 的主要原因是服务端在 06:04 RDMA 崩溃后，大量请求返回连接重置/超时。** 前 18 分钟（05:46~06:04）正常服务期间成功率应正常。

### 4.3 延迟指标

| 指标 | avg | p50 | p75 | p90 | p99 | max |
|---|---|---|---|---|---|---|
| **Latency (s)** | 38.74 | 28.76 | 46.75 | 94.09 | 136.81 | 181.67 |
| **TTFT (ms)** | 10375 | 5985 | 14509 | 24954 | 54148 | 101205 |
| **TPOT (ms)** | 132.84 | 142.6 | 162.3 | 185.21 | 290.13 | 408.12 |
| **ITL (ms)** | 341.77 | 395.04 | 403.9 | 418.07 | 513.54 | 1294.86 |

> - **TTFT 平均 10.4 秒，p99 高达 54 秒**：主要因数据集含 20 档长度，超长请求（728K token 输入）的 prefill 耗时极长。
> - **TPOT 平均 133ms，p99 290ms**：decode 速度偏慢，受 `--max-num-seqs 32` 限制和 PD 分离架构影响。

### 4.4 输入/输出 Token 统计

| 指标 | avg | p50 | p90 | p99 | max |
|---|---|---|---|---|---|
| Input Tokens | 16695 | 1723 | 46838 | 224098 | 727689 |
| Output Tokens | 247 | 119 | 636 | 1218 | 1218 |

> - 输入 token 平均 16695，但 p99 达 224K，max 达 727K（数据集最长档）
> - 输出 token max 1218，**被 `--max-tokens 2048` 截断**（数据集最长档 1045429 被截断到 2048，实际日志显示 max 仅 1218）

### 4.5 缓存与吞吐指标

| 指标 | 值 |
|---|---|
| KV Cache Hit Rate | **24.0%** |
| Spec. Accept Rate | 63.3% |
| Avg Decode Tok/Iter | 2.73 |
| Decode toks/s | 7.53 |

### 4.6 工作负载吞吐

| 指标 (tok/s) | Overall | Last 30s | Steady (drop 20%) |
|---|---|---|---|
| Total Prompt tok/s | 23272 | 3367 | 22663 |
| New Prompt tok/s | 17683 | 2708 | 17054 |
| Cached Prompt tok/s | 5589 | 658 | 5609 |
| Completion tok/s | 344 | 48 | 312 |

> - **Steady state（稳态）Total Prompt tok/s = 22663**，是服务端稳态输入处理能力
> - **Completion tok/s = 312（稳态）**，输出生成能力约 312 tok/s
> - Last 30s 吞吐骤降（3367 vs 23272），因服务端崩溃

### 4.7 百分位延迟详情

| Percentile | Latency(s) | TTFT(ms) | TPOT(ms) | Input tok | Output tok | Output(tok/s) |
|---|---|---|---|---|---|---|
| min | 1.97 | 741 | 9.97 | 207 | 46 | 0.57 |
| 1% | 2.84 | 1000 | 17.24 | 207 | 46 | 1.23 |
| 5% | 4.59 | 1060 | 25.46 | 208 | 46 | 2.22 |
| 10% | 6.21 | 1278 | 32.15 | 703 | 46 | 2.82 |
| 25% | 18.93 | 2512 | 116.69 | 1719 | 119 | 3.95 |
| 50% | 28.76 | 5985 | 142.6 | 1723 | 119 | 5.45 |
| 75% | 46.75 | 14509 | 162.3 | 5049 | 184 | 7.02 |
| 90% | 94.09 | 24954 | 185.21 | 46838 | 636 | 23.01 |
| 95% | 115.83 | 33047 | 206.0 | 90670 | 835 | 29.08 |
| 99% | 136.81 | 54148 | 290.13 | 224098 | 1218 | 39.99 |
| max | 181.67 | 101205 | 408.12 | 727689 | 1218 | 72.98 |

---

## 5. 问题总结与根因

### 5.1 服务端崩溃根因

| 项目 | 内容 |
|---|---|
| **直接原因** | HYBM RDMA 跨设备通信失败（`RaSendWr failed: 32`, error 328100） |
| **崩溃模式** | 两波间歇性爆发（05:57 + 06:04），中间恢复 6 分钟，最终 EngineDeadError |
| **影响范围** | 8 个 TP worker 全部崩溃，服务退出 |

### 5.2 测试结果受影响分析

| 项目 | 内容 |
|---|---|
| 正常服务时段 | 05:46 ~ 06:04（约 18 分钟） |
| 崩溃时段 | 06:04 ~ 06:46（约 42 分钟） |
| 成功率 8.2% | 因 42 分钟崩溃期大量请求失败拉低 |
| 稳态吞吐 | Last 30s 骤降至稳态的 15%（3367 vs 22663） |

> **本次测试结果受服务端崩溃严重影响，指标不能代表服务真实性能。** 正常服务期间（前 18 分钟）的数据有参考价值，但整体指标被 42 分钟崩溃期拉低。

---

## 6. 待调整参数与后续计划

### 6.1 待调整参数

| 参数 | 当前值 | 调整方向 | 原因 |
|---|---|---|---|
| `--parallel` | 100 | 待定 | 服务端 `--max-num-seqs 32`，3 prefiller 总并发上限 96 < 100 |
| `--rate` | 10 | 待定 | 实际 RPS 仅 0.81，远低于 10，说明服务端是瓶颈 |
| `--duration` | 3600 | 待定 | 服务端运行 3.25 小时后崩溃，需观察缩短时长是否能避免 |
| `--max-tokens` | 2048 | 待定 | 截断了数据集长输出档，破坏输出长度分布 |
| `--read-timeout` | 300 | 待定 | 对长输出请求可能过短 |

### 6.2 服务端待排查

| 项目 | 说明 |
|---|---|
| RDMA 通信链路诊断 | 查 HCCP/ROCE 网络链路状态、丢包、队列溢出 |
| `MF_NPU_RDMA_RECV_CQ_DEPTH=128` | 接收队列深度仅 128，可能过小导致 RDMA 完成队列溢出 |
| `MF_NPU_RDMA_MAX_RECV_WR=128` | 最大接收 WR 仅 128，与发送端 32768 严重不对称 |
| HCCP RA 初始化失败 (328002) | 启动时出现，可能是 RDMA 通信不稳定的隐患 |
| 联系昇腾支持 | 需硬件级诊断 RDMA 通信链路 |

---

## 附录 A. 测试输出文件清单

| 文件 | 路径 |
|---|---|
| 服务日志(112) | `logs/serve_20260927030453.log` |
| 服务日志(113) | `logs/serve_20260927030840.log` |
| 服务日志(131) | `logs/serve_20260927023423.log` |
| 服务日志(140) | `logs/serve_20260926131334.log` |
| 测试日志 | `tests/mmc_config_8k_8k_14k_290_100_parallel_10_rate_03_20260927054605.log` |
| 性能摘要 | `tests/outputs/mmc_test_8k_8k_03/20260927_054620/8k_8k_14k_290/performance_summary.txt` |
| 基准摘要 | `tests/outputs/.../parallel_100_number_100000/benchmark_summary.json` |
| 百分位数据 | `tests/outputs/.../parallel_100_number_100000/benchmark_percentile.json` |
| 吞吐数据 | `tests/outputs/.../parallel_100_number_100000/workload_throughput.json` |
| 测试参数 | `tests/outputs/.../parallel_100_number_100000/benchmark_args.json` |
| 基准数据库 | `tests/outputs/.../parallel_100_number_100000/benchmark_data.db` |

## 附录 B. PD 启动脚本完整配置（run_dp_template.sh）

<details>
<summary>展开查看完整脚本</summary>

```bash
nic_name="enp67s0f0np0"
local_ip=$(ifconfig enp67s0f0np0 | grep 'inet ' | awk '{print $2}')

export MF_NPU_RDMA_SEND_CQ_DEPTH=8192
export MF_NPU_RDMA_RECV_CQ_DEPTH=128
export MF_NPU_RDMA_MAX_SEND_WR=8192
export MF_NPU_RDMA_MAX_RECV_WR=128

export HCCL_IF_IP=$local_ip
export GLOO_SOCKET_IFNAME=$nic_name
export TP_SOCKET_IFNAME=$nic_name
export HCCL_SOCKET_IFNAME=$nic_name

export ASCEND_RT_VISIBLE_DEVICES=$1
export OMP_PROC_BIND=false
export OMP_NUM_THREADS=10
export PYTORCH_NPU_ALLOC_CONF=expandable_segments:True
export HCCL_BUFFSIZE=1024
export VLLM_ASCEND_APPLY_DSV4_PATCH=1

export HCCL_OP_EXPANSION_MODE="AIV"
export TASK_QUEUE_ENABLE=1
export VLLM_RPC_TIMEOUT=3600000
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS=30000
export HCCL_EXEC_TIMEOUT=204
export HCCL_CONNECT_TIMEOUT=120

export VLLM_ASCEND_ENABLE_FLASHCOMM1=1

vllm serve /home/j00841616/DeepSeek-V4-Flash-0731-w8a8/ \
    --host 0.0.0.0 \
    --port $2 \
    --max_model_len 1048576 \
    --max-num-batched-tokens 12288 \
    --served-model-name dsv4 \
    --gpu-memory-utilization 0.945 \
    --max-num-seqs 32 \
    --data-parallel-size $3 \
    --tensor-parallel-size $7 \
    --enable-expert-parallel \
    --enable-chunked-prefill \
    --enable-prefix-caching \
    --quantization ascend \
    --block-size 32 \
    --enforce-eager \
    --async-scheduling \
    --no-disable-hybrid-kv-cache-manager \
    --trust-remote-code \
    --kv-transfer-config '{
        "kv_connector": "MultiConnector",
        "kv_role": "kv_producer",
        "engine_id": "0",
        "kv_connector_extra_config": {
            "connectors": [
                {
                    "kv_connector": "MooncakeHybridConnector",
                    "kv_role": "kv_producer",
                    "kv_port": "30000",
                    "kv_connector_extra_config": {
                        "use_ascend_direct": true,
                        "prefill": {"dp_size": 1, "tp_size": 8},
                        "decode": {"dp_size": 8, "tp_size": 1}
                    }
                },
                {
                    "kv_connector": "AscendStoreConnector",
                    "kv_role": "kv_producer",
                    "kv_connector_extra_config": {
                        "backend": "memcache",
                        "lookup_rpc_port": "0",
                        "load_async": false
                    }
                }
            ]
        }
    }'
```
</details>

---

# 测试记录 02 — 32k_32k 混合序列压测

> 测试编号: 20260927-04
> 测试日期: 2026-09-27
> 测试环境: syn-113 (8 × Ascend 910B3, CANN 9.0.1, vLLM-Ascend)
> 报告状态: **服务全程稳定，测试正常完成**

---

## 1. 服务端配置

### 1.1 NPU RDMA 通信配置（run_dp_template.sh）

| 配置项 | 值 | 说明 |
|---|---|---|
| `MF_NPU_RDMA_SEND_CQ_DEPTH` | **32768** | RDMA 发送完成队列深度 |
| `MF_NPU_RDMA_RECV_CQ_DEPTH` | **128** | RDMA 接收完成队列深度 |
| `MF_NPU_RDMA_MAX_SEND_WR` | **32768** | RDMA 最大发送工作请求数 |
| `MF_NPU_RDMA_MAX_RECV_WR` | **128** | RDMA 最大接收工作请求数 |

> 注：启动期日志显示 `MF_NPU_RDMA_MAX_SEND_WR is invalid:32768, use default:32767`，HYBM 自动调整为 32767。

### 1.2 vLLM 启动参数（核心）

| 参数 | 值 | 说明 |
|---|---|---|
| `--max_model_len` | **1048576** | 模型最大上下文长度 1M token |
| `--max-num-batched-tokens` | **12288** | 单批最大 prefill token 数 12K |
| `--max-num-seqs` | **32** | 单实例最大并发序列数 32 |
| `--gpu-memory-utilization` | 0.945 | GPU 显存利用率 94.5% |
| `--tensor-parallel-size` | 8 | 8 卡张量并行 |
| `--block-size` | 32 | KV cache 块大小 32 token |
| `--quantization` | ascend | 昇腾量化 |
| `--enforce-eager` | - | 强制 eager 模式（禁图编译） |
| `--async-scheduling` | - | 异步调度 |
| `--enable-chunked-prefill` | - | 分块 prefill |
| `--enable-prefix-caching` | - | 前缀缓存 |
| `--no-disable-hybrid-kv-cache-manager` | - | 混合 KV cache 管理器 |

### 1.3 PD 分离架构配置（kv-transfer-config）

```json
{
  "kv_connector": "MultiConnector",
  "kv_role": "kv_producer",
  "connectors": [
    {
      "kv_connector": "MooncakeHybridConnector",
      "prefill": {"dp_size": 1, "tp_size": 8},   // prefill: 1 DP × 8 TP
      "decode":  {"dp_size": 8, "tp_size": 1}     // decode: 8 DP × 1 TP
    },
    {
      "kv_connector": "AscendStoreConnector",
      "backend": "memcache"
    }
  ]
}
```

| 阶段 | DP | TP | 说明 |
|---|---|---|---|
| Prefill | 1 | 8 | 1 数据并行 × 8 张量并行（单实例 8 卡并行 prefill） |
| Decode | 8 | 1 | 8 数据并行 × 1 张量并行（8 实例各 1 卡 decode） |

---

## 2. 客户端测试配置

### 2.1 run_mmc_config.sh 配置

| 配置项 | 值 | 说明 |
|---|---|---|
| `--url` | `http://71.10.29.112:1999/v1/chat/completions` | 负载均衡代理地址 |
| `--model` | `dsv4` | 目标模型 |
| `--api` | `openai` | API 协议 |
| `--no-test-connection` | - | 跳过连接预测试 |
| `--dataset` | `line_by_line` | 逐行读取数据集 |
| `--dataset-path` | `gsm8k_4k_12k_c128_cache25_...jsonl` | 混合序列数据集（20 档长度, cache 25%） |
| `--apply-chat-template` | - | 应用 chat 模板 |
| `--max-prompt-length` | 999999 | 最大 prompt 长度上限 |
| `-n` | 100000 | 总请求数上限 |
| `--rate` | 10 | 发送速率 10 req/s |
| `--parallel` | 100 | 并发数 100 |
| `--max-tokens` | 2048 | 单请求最大生成 token 数 |
| `--warmup-num` | 120 | 预热请求数 |
| `--duration` | 3600 | 时长上限 1 小时 |
| `--seed` | 42 | 随机种子 |
| `--stream` | - | 流式输出 |
| `--temperature` | 0.0 | 贪心解码 |
| `--connect-timeout` | 60 | 连接超时 60s |
| `--read-timeout` | 300 | 读超时 300s |
| `--total-timeout` | 600 | 单请求总超时 600s |
| `--outputs-dir` | `outputs/mmc_test_32k_32k` | 输出目录 |
| `--name` | `dsv4` | 测试名称 |

### 2.2 实际生效的结束条件

| 参数 | 值 | 是否先到 |
|---|---|---|
| `--duration` | 3600s（1 小时） | **先到** |
| `-n` | 100000 | 未到（实际 8178 条） |
| `--rate` | 10 req/s | 实际有效 RPS 2.21 |

> 注：`--rate 10` 理论上 1 小时可发 36000 条，但服务端处理慢（混合序列含 727K token 超长输入），实际有效 RPS 2.21，1 小时只发了 8178 条，`--duration 3600` 先到结束。

---

## 3. 执行日志分析

### 3.1 服务端日志：serve_20260927075732.log

| 项目 | 内容 |
|---|---|
| 服务启动时间 | 2026-09-27 07:57:41 |
| 服务运行状态 | **全程稳定，无崩溃** |
| 服务日志最后时间 | 2026-09-27 09:10:26 |
| 服务运行时长 | **约 1.21 小时**（测试期间稳定） |
| 错误总数 | **0 条 ERROR** |
| WARN 总数 | 48 条（全部为启动期，无害） |
| 是否有 vector core timeout (507034) | **无** |
| 是否有 RDMA 通信故障 (328100) | **无** |
| 200 OK 响应数 | 2808 条 |

#### 3.1.1 启动期 WARN（无害）

```
08:04:18 WARN [HYBM dl_hybm_copy_extend.cpp:35 TryLoadLibrary] Environment MEMFABRIC_HYBRID_EXTEND_LIB_PATH is not set.
08:04:18 WARN [HYBM hybm_entity_tag_info.cpp:139 GetTag2TagOpType] Not find opType from tag1:HYBM_DEFAULT_TAG_FOR_EMPTY to tag2:HYBM_DEFAULT_TAG_FOR_EMPTY
08:04:22 WARN [HYBM device_rdma_transport_manager.cpp:607 RaInit] Hccp Init RA failed: 328002 devid:0-7
08:04:25 WARN [HYBM joinable_ranks_qp_manager.cpp:43 GetValidatedDepth] MF_NPU_RDMA_MAX_SEND_WR is invalid:32768, use default:32767
08:04:25 WARN [HYBM hybm_conn_based_segment.cpp:388 AllocMemory] Failed to alloc size:85899345920 (80GB) with hugepage via mmap, error: 12
08:04:25 WARN [HYBM hybm_conn_based_segment.cpp:392 AllocMemory] Trying halMemAlloc for DRAM hugepage allocation.
```

8 卡 RA 初始化失败 + hugepage 不足 80GB 回退 DRAM + MAX_SEND_WR 被调整为 32767，主流程不受影响（服务全程稳定）。

#### 3.1.2 运行期状态

- **服务全程无 ERROR，无崩溃**
- 启动成功：`Started server process [163472]` + `Application startup complete`
- 正常处理请求：2808 条 `200 OK`
- 吞吐正常：首条 `08:09:15 throughput: 172.2 tokens/s` → 末条 `09:10:26 throughput: 0.0 tokens/s`（测试结束后自然降为 0）

### 3.2 客户端测试日志：mmc_config_32k_32k_14k_290_100_parallel_10_rate_20260927080855.log

| 项目 | 内容 |
|---|---|
| 测试启动时间 | 2026-09-27 08:09:09 |
| 测试结束时间 | 2026-09-27 09:11:08 |
| 测试时长 | 3700.42s（约 1.03 小时，duration 正常结束） |
| 错误总数 | 13 条（仅 2 条 `Traceback` + 零星超时） |
| 错误类型 | `asyncio.exceptions.CancelledError`（流式读取被取消） |
| 错误时间 | 08:28:23、08:37:36（各 1 次） |

#### 3.2.1 客户端错误详情

仅 2 次错误，均为 `asyncio.exceptions.CancelledError`：

```
2026-09-27 08:28:23 - evalscope - ERROR: Traceback (most recent call last):
  File ".../aiohttp/streams.py", line 365, in _wait
    await waiter
asyncio.exceptions.CancelledError

2026-09-27 08:37:36 - evalscope - ERROR: Traceback (most recent call last):
  File ".../aiohttp/streams.py", line 365, in _wait
    await waiter
asyncio.exceptions.CancelledError
```

> 2 次错误均为流式响应读取时被取消（可能是单请求超时或并发槽位回收导致），**不影响整体测试**（成功率 100%）。

---

## 4. 测试结果分析

### 4.1 测试结果总览（performance_summary.txt）

| 指标 | 值 | 说明 |
|---|---|---|
| **并发数** | 100 | `--parallel 100` |
| **速率** | 10 req/s | `--rate 10` |
| **总请求数** | 8178 | 受 `--duration 3600` 限制 |
| **实际 RPS** | 2.21 req/s | 低于 10 req/s（服务端处理慢） |
| **生成速率** | 533.77 tok/s | 输出 token 吞吐 |
| **成功率** | **100%** | 8176 成功 / 8178 总（仅 2 失败） |
| **测试时长** | 3700.42 s | 约 1.03 小时 |
| **总生成 token** | 1,975,157 | 约 198 万 token |

### 4.2 请求成功/失败统计

| 项目 | 数量 | 占比 |
|---|---|---|
| 总请求 | 8178 | 100% |
| 成功请求 | **8176** | **99.98%** |
| 失败请求 | **2** | **0.02%** |
| 流式请求 | 8178 | 100% |

> 成功率 99.98%，仅 2 次流式读取取消错误，**测试结果有效，可代表服务真实性能**。

### 4.3 延迟指标

| 指标 | avg | p50 | p75 | p90 | p99 | max |
|---|---|---|---|---|---|---|
| **Latency (s)** | 44.24 | 31.85 | 52.64 | 99.93 | 144.0 | 196.86 |
| **TTFT (ms)** | 12279 | 8196 | 17552 | 28796 | 50128 | 122299 |
| **TPOT (ms)** | 148.75 | 145.52 | 162.02 | 182.23 | 252.07 | 342.82 |
| **ITL (ms)** | 404.31 | 403.71 | 412.65 | 429.68 | 531.24 | 1661.52 |

> - **TTFT 平均 12.3 秒，p99 高达 50 秒**：主要因数据集含 20 档长度，超长请求（728K token 输入）的 prefill 耗时极长。
> - **TPOT 平均 149ms，p99 252ms**：decode 速度稳定，受 `--max-num-seqs 32` 限制和 PD 分离架构影响。

### 4.4 输入/输出 Token 统计

| 指标 | avg | p50 | p90 | p99 | max |
|---|---|---|---|---|---|
| Input Tokens | 14661 | 1723 | 46830 | 224057 | 727689 |
| Output Tokens | 242 | 119 | 622 | 1218 | 1218 |

> - 输入 token 平均 14661，但 p99 达 224K，max 达 727K（数据集最长档）
> - 输出 token max 1218，**被 `--max-tokens 2048` 截断**（数据集最长档 1045429 被截断到 2048，实际日志显示 max 仅 1218）

### 4.5 缓存与吞吐指标

| 指标 | 值 |
|---|---|
| KV Cache Hit Rate | **20.2%** |
| Spec. Accept Rate | 64.7% |
| Avg Decode Tok/Iter | 2.83 |
| Decode toks/s | 6.72 |

### 4.6 工作负载吞吐

| 指标 (tok/s) | Overall | Last 30s | Steady (drop 20%) |
|---|---|---|---|
| Total Prompt tok/s | 32476 | 67586 | 33320 |
| New Prompt tok/s | 25924 | 52094 | 26499 |
| Cached Prompt tok/s | 6552 | 15492 | 6822 |
| Completion tok/s | 535 | 848 | 537 |

> - **Steady state（稳态）Total Prompt tok/s = 33320**，是服务端稳态输入处理能力
> - **Completion tok/s = 537（稳态）**，输出生成能力约 537 tok/s
> - Last 30s 吞吐反而升高（67586 vs 32476），因测试尾声并发请求集中完成

### 4.7 百分位延迟详情

| Percentile | Latency(s) | TTFT(ms) | TPOT(ms) | Input tok | Output tok | Output(tok/s) |
|---|---|---|---|---|---|---|
| min | 8.02 | 1977 | 24.71 | 207 | 46 | 0.62 |
| 1% | 9.87 | 2385 | 81.49 | 207 | 46 | 1.19 |
| 5% | 12.6 | 2418 | 100.91 | 208 | 46 | 2.02 |
| 10% | 17.04 | 2448 | 120.04 | 703 | 46 | 2.54 |
| 25% | 22.85 | 3217 | 132.52 | 1719 | 119 | 3.63 |
| 50% | 31.85 | 8196 | 145.52 | 1723 | 119 | 5.02 |
| 75% | 52.64 | 17552 | 162.02 | 5048 | 184 | 6.12 |
| 90% | 99.93 | 28796 | 182.23 | 46830 | 622 | 6.94 |
| 95% | 119.26 | 35801 | 201.24 | 90661 | 835 | 7.92 |
| 99% | 144.0 | 50128 | 252.07 | 224057 | 1218 | 10.65 |
| max | 196.86 | 122299 | 342.82 | 727689 | 1218 | 19.67 |

---

## 5. 问题总结

### 5.1 服务端状态

| 项目 | 内容 |
|---|---|
| **服务状态** | **全程稳定，无崩溃** |
| **错误数** | 0 ERROR（仅 48 条启动期 WARN） |
| **崩溃** | 无 |
| **200 OK** | 2808 条 |

### 5.2 测试结果有效性

| 项目 | 内容 |
|---|---|
| 成功率 | 99.98%（8176/8178） |
| 失败原因 | 2 次流式读取取消（`asyncio.exceptions.CancelledError`） |
| 结果有效性 | **有效，可代表服务真实性能** |

---

## 6. 待调整参数与后续计划

### 6.1 待调整参数

| 参数 | 当前值 | 调整方向 | 原因 |
|---|---|---|---|
| `--parallel` | 100 | 待定 | 服务端 `--max-num-seqs 32`，3 prefiller 总并发上限 96 < 100 |
| `--rate` | 10 | 待定 | 实际 RPS 2.21，服务端是瓶颈 |
| `--duration` | 3600 | 待定 | 服务端本次全程稳定 |
| `--max-tokens` | 2048 | 待定 | 截断了数据集长输出档，破坏输出长度分布 |
| `--read-timeout` | 300 | 待定 | 对长输出请求可能过短 |

### 6.2 后续测试计划

> **待补充**：后续将调整参数继续测试，测试结果续记于本报告。

---

## 附录 A. 测试输出文件清单

| 文件 | 路径 |
|---|---|
| 测试日志 | `tests/mmc_config_32k_32k_14k_290_100_parallel_10_rate_20260927080855.log` |
| 服务日志 | `logs/serve_20260927075732.log` |
| 性能摘要 | `tests/outputs/mmc_test_32k_32k/20260927_080909/dsv4/performance_summary.txt` |
| 基准摘要 | `tests/outputs/.../parallel_100_number_100000/benchmark_summary.json` |
| 百分位数据 | `tests/outputs/.../parallel_100_number_100000/benchmark_percentile.json` |
| 吞吐数据 | `tests/outputs/.../parallel_100_number_100000/workload_throughput.json` |
| 测试参数 | `tests/outputs/.../parallel_100_number_100000/benchmark_args.json` |
| 基准数据库 | `tests/outputs/.../parallel_100_number_100000/benchmark_data.db` |
