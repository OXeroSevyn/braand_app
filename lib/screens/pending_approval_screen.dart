import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/neo_card.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: NeoCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: AppColors.brand,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'APPROVAL PENDING',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account has been created and is awaiting administrator approval. You will be able to access the dashboard once your account is activated.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) => ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                final success = await auth.refreshUserProfile();
                                if (context.mounted) {
                                  if (success) {
                                    if (auth.isPending) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Still Pending. Please wait for admin approval.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Approved! Redirecting...'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to refresh. Check connection or try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.black,
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black)
                            : Text(
                                'CHECK STATUS',
                                style: GoogleFonts.spaceMono(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<AuthProvider>(context, listen: false)
                            .logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: isDark ? Colors.white : Colors.black,
                          width: 2,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'LOGOUT',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, auth, _) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Debug: ${auth.user?.email} | ${auth.user?.role} | ${auth.user?.status}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ),
      ),
    );
  }
}
