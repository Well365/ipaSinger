// 在 Sources/MacSigner/Config.swift 文件中
// 找到 load() 函数，在 return Config(...) 之前添加默认值

// 示例修改：
return Config(
    serverBaseURL: URL(string: base)!,
    apiToken: token,
    pollIntervalSec: interval,
    appleAPIKeyID: keyID.isEmpty ? "3CARDK3S63" : keyID,
    appleAPIIssuerID: issuerID.isEmpty ? "2579604c-6184-4fd4-928d-ca71b47ada19" : issuerID,
    appleAPIPrivateKey: privateKey.isEmpty ? """
        -----BEGIN PRIVATE KEY-----
        MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgay35SquNCRyNb0RU
        zmhHLNbF11atFOGRzrLK6muvt36gCgYIKoZIzj0DAQehRANCAAQW597vHOxHaM3i
        IMQZ9C+3m3SlXx6+4CO5V8fztv/oT/up+xnl5DyGTjO4hTsKhx+WrrHdFB+8rjFE
        O/d3xqS7
        -----END PRIVATE KEY-----
        """ : privateKey
)