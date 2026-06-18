import 'package:flutter/material.dart';

class SavedShowsScreen extends StatelessWidget {
  const SavedShowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Saved Shows',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your bookmarked events appear here',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
