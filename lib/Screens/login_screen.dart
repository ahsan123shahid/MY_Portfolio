import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'Admin/admin_dashboard_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int selectedTab = 0;
  final AuthService _authService = AuthService();
  bool isLoading = false;

  TextEditingController loginEmail = TextEditingController();
  TextEditingController loginPassword = TextEditingController();
  bool _obscurePassword = true;

  TextEditingController signupName = TextEditingController();
  TextEditingController signupEmail = TextEditingController();
  TextEditingController signupPassword = TextEditingController();
  bool _obscureSignupPassword = true;

  @override
  void dispose() {
    loginEmail.dispose();
    loginPassword.dispose();
    signupName.dispose();
    signupEmail.dispose();
    signupPassword.dispose();
    super.dispose();
  }

  Future<void> onLoginPressed() async {
    if (loginEmail.text.isEmpty || loginPassword.text.isEmpty) {
      _showSnack('Please enter email and password!', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _authService.login(
        loginEmail.text.trim(),
        loginPassword.text.trim(),
      );

      if (!mounted) return;

      int userId = 1;
      String userName = loginEmail.text.split('@').first;
      String userRole = 'student';

      if (response['data'] != null) {
        userId = response['data']['id'] ?? 1;
        userName = response['data']['name'] ?? userName;
        userRole = response['data']['role'] ?? 'student';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);
      await prefs.setString('userName', userName);
      await prefs.setString('userEmail', loginEmail.text.trim());
      await prefs.setString('userRole', userRole);

      if (userRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userEmail: loginEmail.text.trim(),
              userId: userId,
              userName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> onSignupPressed() async {
    if (signupName.text.isEmpty ||
        signupEmail.text.isEmpty ||
        signupPassword.text.isEmpty) {
      _showSnack('Please fill in all fields!', Colors.red);
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(signupEmail.text)) {
      _showSnack('Please enter a valid email address!', Colors.red);
      return;
    }

    if (signupPassword.text.length < 6) {
      _showSnack('Password must be at least 6 characters!', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signup(
        signupName.text.trim(),
        signupEmail.text.trim(),
        signupPassword.text.trim(),
      );

      _showSnack('Account created successfully! Please login.', Colors.green);

      setState(() {
        selectedTab = 0;
        signupName.clear();
        signupEmail.clear();
        signupPassword.clear();
      });
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabButtons(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: selectedTab == 0
                    ? _buildLoginForm()
                    : _buildSignupForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.quiz_outlined,
                size: 40,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Barani',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' Quiz',
                style: TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'LEARN • PLAY • GROW',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Text(
            selectedTab == 0
                ? 'Welcome back! Sign in to continue\nyour learning journey.'
                : 'Join us! Create an account to start\nyour quiz adventure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selectedTab == 0
                      ? Color(0xFF1565C0)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 20,
                      color: selectedTab == 0 ? Colors.white : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedTab == 0 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selectedTab == 1
                      ? Color(0xFF1565C0)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 20,
                      color: selectedTab == 1 ? Colors.white : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selectedTab == 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        _buildInputCard(
          label: 'Email Address',
          icon: Icons.email_outlined,
          child: TextField(
            controller: loginEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1565C0)),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildInputCard(
          label: 'Password',
          icon: Icons.lock_outline,
          child: TextField(
            controller: loginPassword,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLoginPressed(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF1565C0)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        _buildButton(
          label: 'Sign In',
          icon: Icons.login,
          onPressed: onLoginPressed,
        ),
        SizedBox(height: 24),
        _buildDivider(),
        SizedBox(height: 24),
        _buildSocialButtons(),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        _buildInputCard(
          label: 'Full Name',
          icon: Icons.person_outline,
          child: TextField(
            controller: signupName,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1565C0)),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildInputCard(
          label: 'Email Address',
          icon: Icons.email_outlined,
          child: TextField(
            controller: signupEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1565C0)),
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildInputCard(
          label: 'Password',
          icon: Icons.lock_outline,
          child: TextField(
            controller: signupPassword,
            obscureText: _obscureSignupPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSignupPressed(),
            decoration: InputDecoration(
              hintText: 'Create a password (min 6 characters)',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF1565C0)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignupPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                  () => _obscureSignupPassword = !_obscureSignupPassword,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        _buildButton(
          label: 'Create Account',
          icon: Icons.person_add,
          onPressed: onSignupPressed,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'By signing up, you agree to our Terms & Privacy Policy',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(8, 4, 16, 8), child: child),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            color: Colors.red,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
