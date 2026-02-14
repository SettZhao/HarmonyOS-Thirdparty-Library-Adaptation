/**
 * KCP Native Module for OpenHarmony
 * Ported from node-kcp
 */

#include "napi/native_api.h"
#include "hilog/log.h"
#include "kcp/ikcp.h"
#include <cstring>
#include <cstdlib>
#include <map>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x0001
#define LOG_TAG "KCP"

#define RECV_BUFFER_SIZE 4096

// Structure to hold KCP context and output callback
struct KCPContext {
    ikcpcb* kcp;
    napi_ref callbackRef;
    napi_env callbackEnv;
    char* contextStr;
    char* recvBuff;
    unsigned int recvBuffSize;
    
    KCPContext() : kcp(nullptr), callbackRef(nullptr), callbackEnv(nullptr), 
                   contextStr(nullptr), recvBuff(nullptr), recvBuffSize(RECV_BUFFER_SIZE) {
        recvBuff = (char*)malloc(recvBuffSize);
    }
    
    ~KCPContext() {
        if (kcp) {
            ikcp_release(kcp);
            kcp = nullptr;
        }
        if (callbackRef && callbackEnv) {
            napi_delete_reference(callbackEnv, callbackRef);
            callbackRef = nullptr;
        }
        if (contextStr) {
            free(contextStr);
            contextStr = nullptr;
        }
        if (recvBuff) {
            free(recvBuff);
            recvBuff = nullptr;
        }
    }
};

// Global map to store KCP contexts
static std::map<ikcpcb*, KCPContext*> g_kcpContexts;

// KCP output callback
static int kcp_output(const char *buf, int len, ikcpcb *kcp, void *user) {
    KCPContext* ctx = (KCPContext*)user;
    if (!ctx || !ctx->callbackRef || !ctx->callbackEnv) {
        OH_LOG_WARN(LOG_APP, "No output callback set");
        return len;
    }
    
    napi_env env = ctx->callbackEnv;
    napi_value callback;
    napi_get_reference_value(env, ctx->callbackRef, &callback);
    
    // Create ArrayBuffer from data
    void* data;
    napi_value arrayBuffer;
    napi_create_arraybuffer(env, len, &data, &arrayBuffer);
    memcpy(data, buf, len);
    
    // Create arguments array
    napi_value args[3];
    args[0] = arrayBuffer;
    napi_create_int32(env, len, &args[1]);
    
    // Add context if available
    int argc = 2;
    if (ctx->contextStr) {
        napi_create_string_utf8(env, ctx->contextStr, NAPI_AUTO_LENGTH, &args[2]);
        argc = 3;
    }
    
    // Call JavaScript callback
    napi_value global;
    napi_get_global(env, &global);
    napi_value result;
    napi_call_function(env, global, callback, argc, args, &result);
    
    return len;
}

// kcpCreate(conv: number): number
static napi_value KcpCreate(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpCreate requires 1 argument: conv");
        return nullptr;
    }
    
    uint32_t conv;
    napi_get_value_uint32(env, args[0], &conv);
    
    KCPContext* ctx = new KCPContext();
    ctx->kcp = ikcp_create(conv, ctx);
    ctx->kcp->output = kcp_output;
    ctx->callbackEnv = env;
    
    g_kcpContexts[ctx->kcp] = ctx;
    
    OH_LOG_INFO(LOG_APP, "Created KCP instance, conv=%{public}u, kcp=%{public}p", conv, ctx->kcp);
    
    napi_value result;
    napi_create_int64(env, (int64_t)ctx->kcp, &result);
    return result;
}

// kcpRelease(kcp: number): void
static napi_value KcpRelease(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpRelease requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    auto it = g_kcpContexts.find(kcp);
    if (it != g_kcpContexts.end()) {
        delete it->second;
        g_kcpContexts.erase(it);
        OH_LOG_INFO(LOG_APP, "Released KCP instance, kcp=%{public}p", kcp);
    }
    
    return nullptr;
}

// kcpRecv(kcp: number): ArrayBuffer | null
static napi_value KcpRecv(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpRecv requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    auto it = g_kcpContexts.find(kcp);
    if (it == g_kcpContexts.end()) {
        napi_throw_error(env, nullptr, "Invalid KCP handle");
        return nullptr;
    }
    
    KCPContext* ctx = it->second;
    int bufsize = 0;
    unsigned int allsize = 0;
    int len = 0;
    
    while (true) {
        bufsize = ikcp_peeksize(kcp);
        if (bufsize <= 0) {
            break;
        }
        
        allsize += bufsize;
        if (allsize > ctx->recvBuffSize) {
            int align = allsize % 4;
            if (align) {
                allsize += 4 - align;
            }
            ctx->recvBuffSize = allsize;
            ctx->recvBuff = (char*)realloc(ctx->recvBuff, ctx->recvBuffSize);
            if (!ctx->recvBuff) {
                napi_throw_error(env, nullptr, "realloc error");
                return nullptr;
            }
        }
        
        int buflen = ikcp_recv(kcp, ctx->recvBuff + len, bufsize);
        if (buflen <= 0) {
            break;
        }
        len += buflen;
        
        if (kcp->stream == 0) {
            break;
        }
    }
    
    if (len > 0) {
        void* data;
        napi_value arrayBuffer;
        napi_create_arraybuffer(env, len, &data, &arrayBuffer);
        memcpy(data, ctx->recvBuff, len);
        return arrayBuffer;
    }
    
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

// kcpSend(kcp: number, data: ArrayBuffer): number
static napi_value KcpSend(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpSend requires 2 arguments: kcp, data");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    void* data;
    size_t length;
    napi_get_arraybuffer_info(env, args[1], &data, &length);
    
    int ret = ikcp_send(kcp, (const char*)data, (int)length);
    
    napi_value result;
    napi_create_int32(env, ret, &result);
    return result;
}

// kcpInput(kcp: number, data: ArrayBuffer): number
static napi_value KcpInput(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpInput requires 2 arguments: kcp, data");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    void* data;
    size_t length;
    napi_get_arraybuffer_info(env, args[1], &data, &length);
    
    int ret = ikcp_input(kcp, (const char*)data, (int)length);
    
    napi_value result;
    napi_create_int32(env, ret, &result);
    return result;
}

// kcpUpdate(kcp: number, current: number): void
static napi_value KcpUpdate(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpUpdate requires 2 arguments: kcp, current");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int64_t current;
    napi_get_value_int64(env, args[1], &current);
    
    ikcp_update(kcp, (IUINT32)(current & 0xfffffffful));
    
    return nullptr;
}

// kcpCheck(kcp: number, current: number): number
static napi_value KcpCheck(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpCheck requires 2 arguments: kcp, current");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int64_t current;
    napi_get_value_int64(env, args[1], &current);
    
    IUINT32 cur = (IUINT32)(current & 0xfffffffful);
    IUINT32 next = ikcp_check(kcp, cur);
    IUINT32 diff = next > cur ? next - cur : 0;
    
    napi_value result;
    napi_create_uint32(env, diff, &result);
    return result;
}

// kcpFlush(kcp: number): void
static napi_value KcpFlush(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpFlush requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    ikcp_flush(kcp);
    
    return nullptr;
}

// kcpPeeksize(kcp: number): number
static napi_value KcpPeeksize(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpPeeksize requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int size = ikcp_peeksize(kcp);
    
    napi_value result;
    napi_create_int32(env, size, &result);
    return result;
}

// kcpSetmtu(kcp: number, mtu: number): number
static napi_value KcpSetmtu(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpSetmtu requires 2 arguments: kcp, mtu");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int32_t mtu;
    napi_get_value_int32(env, args[1], &mtu);
    
    int ret = ikcp_setmtu(kcp, mtu);
    
    napi_value result;
    napi_create_int32(env, ret, &result);
    return result;
}

// kcpWndsize(kcp: number, sndwnd: number, rcvwnd: number): number
static napi_value KcpWndsize(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "kcpWndsize requires 3 arguments: kcp, sndwnd, rcvwnd");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int32_t sndwnd, rcvwnd;
    napi_get_value_int32(env, args[1], &sndwnd);
    napi_get_value_int32(env, args[2], &rcvwnd);
    
    int ret = ikcp_wndsize(kcp, sndwnd, rcvwnd);
    
    napi_value result;
    napi_create_int32(env, ret, &result);
    return result;
}

// kcpWaitsnd(kcp: number): number
static napi_value KcpWaitsnd(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpWaitsnd requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int count = ikcp_waitsnd(kcp);
    
    napi_value result;
    napi_create_int32(env, count, &result);
    return result;
}

// kcpNodelay(kcp: number, nodelay: number, interval: number, resend: number, nc: number): number
static napi_value KcpNodelay(napi_env env, napi_callback_info info) {
    size_t argc = 5;
    napi_value args[5];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 5) {
        napi_throw_error(env, nullptr, "kcpNodelay requires 5 arguments: kcp, nodelay, interval, resend, nc");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int32_t nodelay, interval, resend, nc;
    napi_get_value_int32(env, args[1], &nodelay);
    napi_get_value_int32(env, args[2], &interval);
    napi_get_value_int32(env, args[3], &resend);
    napi_get_value_int32(env, args[4], &nc);
    
    int ret = ikcp_nodelay(kcp, nodelay, interval, resend, nc);
    
    napi_value result;
    napi_create_int32(env, ret, &result);
    return result;
}

// kcpSetStream(kcp: number, stream: number): void
static napi_value KcpSetStream(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpSetStream requires 2 arguments: kcp, stream");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    int32_t stream;
    napi_get_value_int32(env, args[1], &stream);
    
    kcp->stream = stream;
    
    return nullptr;
}

// kcpSetContext(kcp: number, context: string): void
static napi_value KcpSetContext(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpSetContext requires 2 arguments: kcp, context");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    auto it = g_kcpContexts.find(kcp);
    if (it == g_kcpContexts.end()) {
        napi_throw_error(env, nullptr, "Invalid KCP handle");
        return nullptr;
    }
    
    KCPContext* ctx = it->second;
    
    size_t strLen;
    napi_get_value_string_utf8(env, args[1], nullptr, 0, &strLen);
    
    if (ctx->contextStr) {
        free(ctx->contextStr);
    }
    ctx->contextStr = (char*)malloc(strLen + 1);
    napi_get_value_string_utf8(env, args[1], ctx->contextStr, strLen + 1, &strLen);
    
    return nullptr;
}

// kcpGetContext(kcp: number): string
static napi_value KcpGetContext(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "kcpGetContext requires 1 argument: kcp");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    auto it = g_kcpContexts.find(kcp);
    if (it == g_kcpContexts.end()) {
        napi_throw_error(env, nullptr, "Invalid KCP handle");
        return nullptr;
    }
    
    KCPContext* ctx = it->second;
    
    napi_value result;
    if (ctx->contextStr) {
        napi_create_string_utf8(env, ctx->contextStr, NAPI_AUTO_LENGTH, &result);
    } else {
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
    }
    return result;
}

// Special function to set output callback (not exposed in d.ts, used by ArkTS wrapper)
static napi_value KcpSetOutputCallback(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "kcpSetOutputCallback requires 2 arguments: kcp, callback");
        return nullptr;
    }
    
    int64_t kcpPtr;
    napi_get_value_int64(env, args[0], &kcpPtr);
    ikcpcb* kcp = (ikcpcb*)kcpPtr;
    
    auto it = g_kcpContexts.find(kcp);
    if (it == g_kcpContexts.end()) {
        napi_throw_error(env, nullptr, "Invalid KCP handle");
        return nullptr;
    }
    
    KCPContext* ctx = it->second;
    
    // Delete old reference if exists
    if (ctx->callbackRef) {
        napi_delete_reference(env, ctx->callbackRef);
    }
    
    // Create new reference
    napi_create_reference(env, args[1], 1, &ctx->callbackRef);
    
    OH_LOG_INFO(LOG_APP, "Set output callback for KCP instance, kcp=%{public}p", kcp);
    
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "kcpCreate", nullptr, KcpCreate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpRelease", nullptr, KcpRelease, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpRecv", nullptr, KcpRecv, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpSend", nullptr, KcpSend, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpInput", nullptr, KcpInput, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpUpdate", nullptr, KcpUpdate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpCheck", nullptr, KcpCheck, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpFlush", nullptr, KcpFlush, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpPeeksize", nullptr, KcpPeeksize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpSetmtu", nullptr, KcpSetmtu, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpWndsize", nullptr, KcpWndsize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpWaitsnd", nullptr, KcpWaitsnd, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpNodelay", nullptr, KcpNodelay, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpSetStream", nullptr, KcpSetStream, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpSetContext", nullptr, KcpSetContext, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpGetContext", nullptr, KcpGetContext, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "kcpSetOutputCallback", nullptr, KcpSetOutputCallback, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "kcp",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterKcpModule(void)
{
    napi_module_register(&demoModule);
}

