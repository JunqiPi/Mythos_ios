# Mythos iOS - Swift移动端框架

一个现代化的Swift移动端框架，用于Mythos平台的iOS和未来跨平台开发。

## 🚀 技术栈

### 核心技术
- **Swift 5.9+** - 现代Swift语言特性
- **SwiftUI 5** - 声明式UI框架
- **iOS 17+** - 最新iOS平台支持
- **Swift Package Manager** - 依赖管理

### 架构与设计
- **The Composable Architecture (TCA)** - 单向数据流架构
- **Async/Await** - 现代异步编程
- **Combine** - 响应式编程
- **MVVM + TCA** - 分层架构设计

### 网络与数据
- **Alamofire** - 网络请求库
- **Codable** - JSON序列化
- **UserDefaults/Keychain** - 本地数据存储
- **Core Data/SwiftData** - 本地数据库（可选）

### UI与用户体验
- **Kingfisher** - 图片缓存加载
- **Factory** - 依赖注入
- **Swift Collections** - 高性能集合
- **SwiftLint** - 代码规范检查

## 📁 项目结构

```
mythos_ios/
├── Package.swift                    # 主Package配置
├── Sources/
│   ├── MythosCore/                 # 核心业务逻辑
│   │   ├── Models/                 # 数据模型
│   │   │   ├── User.swift         # 用户模型
│   │   │   ├── Book.swift         # 书籍模型
│   │   │   └── ...
│   │   ├── Services/              # 业务服务
│   │   └── Utils/                 # 工具类
│   ├── MythosNetworking/          # 网络层
│   │   ├── APIClient.swift        # API客户端
│   │   ├── APIEndpoint.swift      # API端点定义
│   │   └── Services/              # 网络服务
│   │       ├── AuthenticationService.swift
│   │       ├── BookService.swift
│   │       └── ...
│   └── MythosUI/                  # UI层
│       ├── Features/              # 功能模块
│       │   ├── Authentication/    # 认证模块
│       │   ├── Books/            # 书籍模块
│       │   ├── Reading/          # 阅读模块
│       │   └── ...
│       ├── Components/            # 共享组件
│       └── Utils/                # UI工具
├── MythosApp/                     # iOS应用
│   ├── Package.swift
│   └── Sources/
│       ├── MythosApp.swift       # 应用入口
│       ├── Features/             # 应用级功能
│       └── Resources/            # 资源文件
└── Tests/                        # 测试
    ├── MythosCoreTests/
    ├── MythosNetworkingTests/
    └── MythosUITests/
```

## 🏗️ 架构设计

### 分层架构

1. **MythosCore** - 核心层
   - 业务模型定义
   - 业务逻辑实现
   - 跨平台共享代码

2. **MythosNetworking** - 网络层
   - API客户端封装
   - 网络服务抽象
   - 错误处理和重试机制

3. **MythosUI** - UI层
   - SwiftUI视图组件
   - TCA Feature实现
   - 平台特定UI逻辑

4. **MythosApp** - 应用层
   - 应用配置和启动
   - 依赖注入设置
   - 平台特定功能

### 状态管理 (TCA)

```swift
// Feature结构
struct BookListFeature: Reducer {
    struct State: Equatable {
        var books: [Book] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case booksLoaded([Book])
        case bookTapped(Book.ID)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // 状态处理逻辑
        }
    }
}
```

### 网络层设计

```swift
// 统一的API调用方式
let books: [Book] = try await apiClient.get(.books)
let user: User = try await apiClient.post(.login, parameters: credentials)
```

## 🛠️ 开发指南

### 环境要求

- **Xcode 15.0+**
- **iOS 17.0+ 模拟器/设备**
- **macOS 14.0+**

### 本地开发设置

1. **克隆项目**
```bash
git clone <repository-url>
cd mythos_ios
```

2. **打开项目**
```bash
# 使用Xcode打开Package.swift
open Package.swift

# 或使用命令行
swift package resolve
```

3. **配置后端API**
```swift
// 在APIClient中配置后端地址
let baseURL = URL(string: "http://localhost:8000/api")!
```

4. **运行应用**
```bash
# 命令行运行
swift run MythosApp

# 或在Xcode中选择scheme运行
```

### 代码规范

1. **命名约定**
   - 类型：`PascalCase`
   - 变量/函数：`camelCase`
   - 常量：`camelCase`
   - 枚举案例：`camelCase`

2. **架构原则**
   - 单一职责原则
   - 依赖注入
   - 可测试性优先
   - 响应式编程

3. **性能考虑**
   - 使用`@frozen`结构体
   - 避免不必要的视图更新
   - 合理使用`@MainActor`
   - 优化网络请求

### 测试策略

```swift
// 单元测试示例
@Test func testUserLogin() async throws {
    let mockAPIClient = MockAPIClient()
    let authService = AuthenticationService(apiClient: mockAPIClient)
    
    let user = try await authService.login(
        email: "test@example.com",
        password: "password"
    )
    
    #expect(user.email == "test@example.com")
}
```

## 🔄 与后端集成

### API接口对应

本框架与`Mythos-api`后端完全兼容：

```
后端路由                    -> iOS Service
/api/auth/*                -> AuthenticationService
/api/books/*               -> BookService
/api/users/*               -> UserService
/api/reading-progress/*    -> ReadingProgressService
```

### 数据模型映射

```swift
// Swift模型自动映射后端JSON
struct User: Codable {
    let id: String
    let username: String
    let email: String
    // 自动处理snake_case <-> camelCase转换
}
```

## 🚀 未来扩展性

### 跨平台支持

1. **Android支持**
   - 核心业务逻辑可复用
   - 网络层可适配Kotlin Multiplatform
   - UI层需重新实现

2. **macOS支持**
   - 直接兼容，minimal changes
   - 可能需要UI适配

3. **Web支持**
   - 通过Swift for WebAssembly
   - 或重写为TypeScript

### 性能优化

1. **本地缓存**
   - 图书内容离线存储
   - 用户偏好本地化
   - 智能预加载

2. **网络优化**
   - 请求合并
   - 响应缓存
   - 增量更新

## 📚 学习资源

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [SwiftUI官方文档](https://developer.apple.com/swiftui/)
- [Swift Package Manager指南](https://swift.org/package-manager/)
- [Swift并发编程](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 🤝 贡献指南

1. Fork项目
2. 创建feature分支
3. 提交更改
4. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看[LICENSE](LICENSE)文件了解详情。

## 📞 联系方式

如有问题或建议，请创建Issue或联系开发团队。

---

**注意**: 这是一个现代化的Swift移动端框架，采用了最新的iOS开发最佳实践。框架设计考虑了未来的可扩展性和跨平台需求。 