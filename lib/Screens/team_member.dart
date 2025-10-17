import 'package:flutter/material.dart';

// --- Data Model ---
class TeamMember {
  final String name;
  final String role;
  final String details;
  final Color avatarColor;
  final IconData icon;

  TeamMember({
    required this.name,
    required this.role,
    required this.details,
    required this.avatarColor,
    required this.icon,
  });
}

// --- Team Data (Supervisor + 3 Members) ---
final List<TeamMember> team = [
  TeamMember(
    name: 'Dr. Evelyn Reed',
    role: 'Supervisor / Project Lead',
    details: 'Oversees technical direction, strategic planning, and quality assurance.',
    avatarColor: Colors.teal.shade800,
    icon: Icons.local_police,
  ),
  TeamMember(
    name: 'Alex Johnson',
    role: 'Lead Developer (Frontend)',
    details: 'Responsible for the user interface, state management, and overall UX implementation.',
    avatarColor: Colors.blue.shade600,
    icon: Icons.code,
  ),
  TeamMember(
    name: 'Maria Sanchez',
    role: 'Backend & Database Specialist',
    details: 'Manages API design, data integrity, and cloud integration (Firestore/Auth).',
    avatarColor: Colors.purple.shade600,
    icon: Icons.storage,
  ),
  TeamMember(
    name: 'Kenji Tanaka',
    role: 'Testing & Deployment Engineer',
    details: 'Handles unit and integration tests, CI/CD pipelines, and app store submission.',
    avatarColor: Colors.orange.shade600,
    icon: Icons.bug_report,
  ),
];

// --- Reusable Widget for a Team Member Card ---
class TeamMemberCard extends StatelessWidget {
  final TeamMember member;

  const TeamMemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    // Determine the color gradient based on the role
    Color startColor = member.role.contains('Supervisor')
        ? Colors.teal.shade50
        : Colors.white;
    Color endColor = member.role.contains('Supervisor')
        ? Colors.teal.shade100
        : Colors.grey.shade50;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: member.role.contains('Supervisor')
            ? BorderSide(color: Colors.teal.shade700, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Avatar with Icon
                CircleAvatar(
                  radius: 30,
                  backgroundColor: member.avatarColor,
                  child: Icon(
                    member.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                // Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: member.role.contains('Supervisor')
                              ? Colors.teal.shade900
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.role,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: member.role.contains('Supervisor')
                              ? Colors.teal.shade600
                              : Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25, color: Colors.black12),
            // Details Section
            Text(
              'Key Responsibilities:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member.details,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Screen Widget ---
class TeamDetailsScreen extends StatelessWidget {
  const TeamDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Development Team Directory'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Light background for the list
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: team.length,
          itemBuilder: (context, index) {
            // Add a small header before the first card (Supervisor)
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Project Leadership',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  TeamMemberCard(member: team[index]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Text(
                      'Core Development Team',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              );
            }
            // Normal card for team members
            return TeamMemberCard(member: team[index]);
          },
        ),
      ),
    );
  }
}




