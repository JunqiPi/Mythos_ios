import Foundation
import MythosCore
import Logging

// MARK: - Authentication Service
@MainActor
public final class AuthenticationService: @unchecked Sendable {
    private let apiClient: APIClient
    private let logger: Logger
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.logger = Logger(label: "com.mythos.auth")
    }
    
    // MARK: - Login
    public func login(email: String, password: String) async throws -> User {
        logger.info("Attempting login for email: \(email)")
        
        let parameters = [
            "email": email,
            "password": password
        ]
        
        let response: LoginResponse = try await apiClient.post(
            .login,
            parameters: parameters,
            requiresAuth: false
        )
        
        // 保存认证令牌
        await apiClient.setAuthToken(response.token)
        
        // 缓存用户信息
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        logger.info("Login successful for user: \(response.user.username)")
        return response.user
    }
    
    // MARK: - Register
    public func register(username: String, email: String, password: String) async throws -> User {
        logger.info("Attempting registration for email: \(email)")
        
        let parameters = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        let response: RegisterResponse = try await apiClient.post(
            .register,
            parameters: parameters,
            requiresAuth: false
        )
        
        // 保存认证令牌
        await apiClient.setAuthToken(response.token)
        
        // 缓存用户信息
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        logger.info("Registration successful for user: \(response.user.username)")
        return response.user
    }
    
    // MARK: - Logout
    public func logout() async {
        logger.info("Logging out user")
        
        do {
            let _: EmptyResponse = try await apiClient.post(.logout)
        } catch {
            logger.error("Logout request failed: \(error)")
            // 即使请求失败，也要清除本地状态
        }
        
        // 清除本地认证状态
        await apiClient.clearAuthToken()
        
        logger.info("Logout completed")
    }
    
    // MARK: - Get Current User
    public func getCurrentUser() async throws -> User {
        logger.info("Fetching current user")
        
        let user: User = try await apiClient.get(.currentUser)
        
        // 更新缓存
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        return user
    }
    
    // MARK: - Refresh Token
    public func refreshToken() async throws -> String {
        logger.info("Refreshing authentication token")
        
        let response: RefreshTokenResponse = try await apiClient.post(.refreshToken)
        
        // 更新令牌
        await apiClient.setAuthToken(response.token)
        
        logger.info("Token refresh successful")
        return response.token
    }
    
    // MARK: - Forgot Password
    public func forgotPassword(email: String) async throws {
        logger.info("Requesting password reset for email: \(email)")
        
        let parameters = ["email": email]
        
        let _: EmptyResponse = try await apiClient.post(
            .forgotPassword,
            parameters: parameters,
            requiresAuth: false
        )
        
        logger.info("Password reset email sent")
    }
    
    // MARK: - Reset Password
    public func resetPassword(token: String, newPassword: String) async throws -> User {
        logger.info("Resetting password with token")
        
        let parameters = [
            "password": newPassword,
            "confirmPassword": newPassword
        ]
        
        let response: LoginResponse = try await apiClient.post(
            .resetPassword(token: token),
            parameters: parameters,
            requiresAuth: false
        )
        
        // 保存新的认证令牌
        await apiClient.setAuthToken(response.token)
        
        // 缓存用户信息
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        logger.info("Password reset successful")
        return response.user
    }
    
    // MARK: - Verify Email
    public func verifyEmail(token: String) async throws -> User {
        logger.info("Verifying email with token")
        
        let response: LoginResponse = try await apiClient.post(
            .verifyEmail(token: token),
            requiresAuth: false
        )
        
        // 更新认证令牌
        await apiClient.setAuthToken(response.token)
        
        // 缓存用户信息
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        logger.info("Email verification successful")
        return response.user
    }
    
    // MARK: - Update Profile
    public func updateProfile(
        firstName: String?,
        lastName: String?,
        bio: String?
    ) async throws -> User {
        guard let currentUser = await apiClient.currentUser else {
            throw APIError.unauthorized
        }
        
        logger.info("Updating user profile")
        
        var parameters: [String: Any] = [:]
        if let firstName = firstName { parameters["firstName"] = firstName }
        if let lastName = lastName { parameters["lastName"] = lastName }
        if let bio = bio { parameters["bio"] = bio }
        
        let user: User = try await apiClient.put(
            .updateUserProfile(userId: currentUser.id),
            parameters: parameters
        )
        
        // 更新缓存
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
        
        logger.info("Profile update successful")
        return user
    }
    
    // MARK: - Change Password
    public func changePassword(
        currentPassword: String,
        newPassword: String
    ) async throws {
        logger.info("Changing user password")
        
        let parameters = [
            "currentPassword": currentPassword,
            "newPassword": newPassword,
            "confirmPassword": newPassword
        ]
        
        let _: EmptyResponse = try await apiClient.put(
            .updateUserProfile(userId: await apiClient.currentUser?.id ?? ""),
            parameters: parameters
        )
        
        logger.info("Password change successful")
    }
    
    // MARK: - Delete Account
    public func deleteAccount(password: String) async throws {
        guard let currentUser = await apiClient.currentUser else {
            throw APIError.unauthorized
        }
        
        logger.info("Deleting user account")
        
        let parameters = ["password": password]
        
        let _: EmptyResponse = try await apiClient.delete(.deleteUser(userId: currentUser.id))
        
        // 清除本地状态
        await apiClient.clearAuthToken()
        
        logger.info("Account deletion successful")
    }
}

// MARK: - Response Models
public struct LoginResponse: Codable {
    public let token: String
    public let user: User
    public let expiresIn: TimeInterval?
    
    public init(token: String, user: User, expiresIn: TimeInterval? = nil) {
        self.token = token
        self.user = user
        self.expiresIn = expiresIn
    }
}

public struct RegisterResponse: Codable {
    public let token: String
    public let user: User
    public let emailVerificationRequired: Bool
    
    public init(token: String, user: User, emailVerificationRequired: Bool = false) {
        self.token = token
        self.user = user
        self.emailVerificationRequired = emailVerificationRequired
    }
}

public struct RefreshTokenResponse: Codable {
    public let token: String
    public let expiresIn: TimeInterval?
    
    public init(token: String, expiresIn: TimeInterval? = nil) {
        self.token = token
        self.expiresIn = expiresIn
    }
} 