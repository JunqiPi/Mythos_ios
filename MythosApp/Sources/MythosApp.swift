import SwiftUI
import ComposableArchitecture
import MythosCore
import MythosNetworking
import MythosUI
import Factory

@main
struct MythosApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(initialState: RootFeature.State()) {
                    RootFeature()
                        ._printChanges()
                }
            )
            .preferredColorScheme(.dark) // 默认深色模式
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        // 配置依赖注入
        setupDependencies()
        
        // 配置外观
        configureAppearance()
        
        // 配置网络
        configureNetworking()
    }
    
    private func setupDependencies() {
        // 注册服务
        Container.shared.register(APIClient.self) { APIClient.shared }
        Container.shared.register(AuthenticationService.self) { 
            AuthenticationService(apiClient: APIClient.shared) 
        }
        Container.shared.register(BookService.self) { 
            BookService(apiClient: APIClient.shared) 
        }
        Container.shared.register(UserService.self) { 
            UserService(apiClient: APIClient.shared) 
        }
    }
    
    private func configureAppearance() {
        // 配置导航栏外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // 配置标签栏外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    private func configureNetworking() {
        // 配置网络基础URL
        #if DEBUG
        // 开发环境
        #elseif STAGING
        // 测试环境
        #else
        // 生产环境
        #endif
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 应用启动配置
        return true
    }
    
    // MARK: - 推送通知
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // 处理推送通知设备令牌
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Root Feature
struct RootFeature: Reducer {
    struct State: Equatable {
        var authenticationState: AuthenticationFeature.State = .init()
        var mainTabState: MainTabFeature.State = .init()
        
        var isAuthenticated: Bool {
            authenticationState.isLoggedIn
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case authentication(AuthenticationFeature.Action)
        case mainTab(MainTabFeature.Action)
        case checkAuthenticationStatus
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Scope(state: \.authenticationState, action: /Action.authentication) {
            AuthenticationFeature()
        }
        
        Scope(state: \.mainTabState, action: /Action.mainTab) {
            MainTabFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkAuthenticationStatus)
                
            case .checkAuthenticationStatus:
                // 检查认证状态的逻辑
                return .none
                
            case .authentication(.loginSuccess):
                // 登录成功，切换到主界面
                return .none
                
            case .authentication(.logout):
                // 登出，清除状态
                state.mainTabState = .init()
                return .none
                
            case .authentication:
                return .none
                
            case .mainTab:
                return .none
            }
        }
    }
}

// MARK: - Root View
struct RootView: View {
    let store: StoreOf<RootFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isAuthenticated {
                    MainTabView(
                        store: store.scope(
                            state: \.mainTabState,
                            action: RootFeature.Action.mainTab
                        )
                    )
                } else {
                    AuthenticationView(
                        store: store.scope(
                            state: \.authenticationState,
                            action: RootFeature.Action.authentication
                        )
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewStore.isAuthenticated)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: - Dependency Registration
extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

private enum APIClientKey: DependencyKey {
    static let liveValue = APIClient.shared
    static let testValue = APIClient(baseURL: URL(string: "http://localhost:8000/api")!)
} 