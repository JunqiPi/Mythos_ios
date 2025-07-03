import Foundation
import ComposableArchitecture
import MythosCore
import MythosNetworking

// MARK: - Authentication Feature
public struct AuthenticationFeature: Reducer {
    public struct State: Equatable {
        public var isLoggedIn: Bool = false
        public var currentUser: User?
        public var loginState: LoginFeature.State = .init()
        public var registerState: RegisterFeature.State = .init()
        public var selectedTab: AuthTab = .login
        public var isLoading: Bool = false
        public var errorMessage: String?
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case tabSelected(AuthTab)
        case login(LoginFeature.Action)
        case register(RegisterFeature.Action)
        case loginSuccess(User)
        case logout
        case clearError
        case checkAuthenticationStatus
    }
    
    public enum AuthTab: String, CaseIterable {
        case login = "登录"
        case register = "注册"
    }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.authenticationService) var authService
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.loginState, action: /Action.login) {
            LoginFeature()
        }
        
        Scope(state: \.registerState, action: /Action.register) {
            RegisterFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkAuthenticationStatus)
                
            case .tabSelected(let tab):
                state.selectedTab = tab
                state.errorMessage = nil
                return .none
                
            case .checkAuthenticationStatus:
                state.isLoading = true
                return .run { send in
                    do {
                        let user = try await authService.getCurrentUser()
                        await send(.loginSuccess(user))
                    } catch {
                        // 用户未登录或令牌无效
                        state.isLoading = false
                    }
                }
                
            case .login(.loginTapped):
                state.isLoading = true
                return .none
                
            case .login(.loginResponse(.success(let user))):
                return .send(.loginSuccess(user))
                
            case .login(.loginResponse(.failure(let error))):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .register(.registerSuccess(let user)):
                return .send(.loginSuccess(user))
                
            case .loginSuccess(let user):
                state.isLoggedIn = true
                state.currentUser = user
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case .logout:
                state.isLoggedIn = false
                state.currentUser = nil
                state.loginState = .init()
                state.registerState = .init()
                return .run { _ in
                    await authService.logout()
                }
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case .login:
                return .none
                
            case .register:
                return .none
            }
        }
    }
}

// MARK: - Login Feature
public struct LoginFeature: Reducer {
    public struct State: Equatable {
        public var email: String = ""
        public var password: String = ""
        public var isLoading: Bool = false
        public var showPassword: Bool = false
        public var rememberMe: Bool = false
        
        public var isFormValid: Bool {
            !email.isEmpty && !password.isEmpty && email.contains("@")
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case showPasswordToggled
        case rememberMeToggled
        case loginTapped
        case loginResponse(Result<User, APIError>)
        case forgotPasswordTapped
    }
    
    @Dependency(\.authenticationService) var authService
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .emailChanged(let email):
                state.email = email
                return .none
                
            case .passwordChanged(let password):
                state.password = password
                return .none
                
            case .showPasswordToggled:
                state.showPassword.toggle()
                return .none
                
            case .rememberMeToggled:
                state.rememberMe.toggle()
                return .none
                
            case .loginTapped:
                guard state.isFormValid else { return .none }
                
                state.isLoading = true
                return .run { [email = state.email, password = state.password] send in
                    do {
                        let user = try await authService.login(email: email, password: password)
                        await send(.loginResponse(.success(user)))
                    } catch let error as APIError {
                        await send(.loginResponse(.failure(error)))
                    } catch {
                        await send(.loginResponse(.failure(.networkError(error))))
                    }
                }
                
            case .loginResponse:
                state.isLoading = false
                return .none
                
            case .forgotPasswordTapped:
                // TODO: 实现忘记密码功能
                return .none
            }
        }
    }
}

// MARK: - Register Feature
public struct RegisterFeature: Reducer {
    public struct State: Equatable {
        public var username: String = ""
        public var email: String = ""
        public var password: String = ""
        public var confirmPassword: String = ""
        public var isLoading: Bool = false
        public var showPassword: Bool = false
        public var showConfirmPassword: Bool = false
        public var agreeToTerms: Bool = false
        
        public var isFormValid: Bool {
            !username.isEmpty &&
            !email.isEmpty &&
            email.contains("@") &&
            !password.isEmpty &&
            password.count >= 6 &&
            password == confirmPassword &&
            agreeToTerms
        }
        
        public var passwordsMatch: Bool {
            password == confirmPassword && !confirmPassword.isEmpty
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case usernameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case confirmPasswordChanged(String)
        case showPasswordToggled
        case showConfirmPasswordToggled
        case agreeToTermsToggled
        case registerTapped
        case registerResponse(Result<User, APIError>)
        case registerSuccess(User)
    }
    
    @Dependency(\.authenticationService) var authService
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .usernameChanged(let username):
                state.username = username
                return .none
                
            case .emailChanged(let email):
                state.email = email
                return .none
                
            case .passwordChanged(let password):
                state.password = password
                return .none
                
            case .confirmPasswordChanged(let confirmPassword):
                state.confirmPassword = confirmPassword
                return .none
                
            case .showPasswordToggled:
                state.showPassword.toggle()
                return .none
                
            case .showConfirmPasswordToggled:
                state.showConfirmPassword.toggle()
                return .none
                
            case .agreeToTermsToggled:
                state.agreeToTerms.toggle()
                return .none
                
            case .registerTapped:
                guard state.isFormValid else { return .none }
                
                state.isLoading = true
                return .run { [username = state.username, email = state.email, password = state.password] send in
                    do {
                        let user = try await authService.register(
                            username: username,
                            email: email,
                            password: password
                        )
                        await send(.registerResponse(.success(user)))
                    } catch let error as APIError {
                        await send(.registerResponse(.failure(error)))
                    } catch {
                        await send(.registerResponse(.failure(.networkError(error))))
                    }
                }
                
            case .registerResponse(.success(let user)):
                state.isLoading = false
                return .send(.registerSuccess(user))
                
            case .registerResponse(.failure):
                state.isLoading = false
                return .none
                
            case .registerSuccess:
                return .none
            }
        }
    }
}

// MARK: - Dependency Registration
extension DependencyValues {
    public var authenticationService: AuthenticationService {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}

private enum AuthenticationServiceKey: DependencyKey {
    static let liveValue = AuthenticationService(apiClient: APIClient.shared)
    static let testValue = AuthenticationService(apiClient: APIClient.shared)
} 