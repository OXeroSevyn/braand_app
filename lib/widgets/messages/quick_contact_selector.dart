import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../models/user.dart';
import '../user_avatar.dart';

class QuickContactSelector extends StatelessWidget {
  final List<User> users;
  final User? selectedUser;
  final Function(User) onUserSelected;

  const QuickContactSelector({
    super.key,
    required this.users,
    required this.selectedUser,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final user = users[index];
          final isSelected = selectedUser?.id == user.id;

          return GestureDetector(
            onTap: () => onUserSelected(user),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.brand, Color(0xFFD4FF7A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: !isSelected
                        ? Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!,
                            width: 2,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brand.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    child: UserAvatar(
                      avatarUrl: user.avatar,
                      name: user.name,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.name.split(' ')[0],
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
