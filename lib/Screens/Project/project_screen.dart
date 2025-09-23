import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Component/round_button.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String selectedFilter = "All";
  final List<String> filters = ["All", "Recent", "Completed", "Draft"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Your Projects",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Create new project feature coming soon!"),
                  backgroundColor: Colors.purple,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "All Projects",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "12 total projects",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RoundButton(
                    title: "New Project",
                    onPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Create new project feature coming soon!",
                          ),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                    leadingIcon: Icons.add,
                    leadingIconColor: Colors.white,
                    bgColor: AppColors.purpleColor,
                    borderRadius: 12,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.purpleColor
                              : AppColors.darkGreyColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purpleColor
                                : AppColors.greyColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Projects grid
              Expanded(child: _buildProjectsGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    // Sample project data
    final projects = [
      {
        "title": "Demo Video 1",
        "createdDate": "9/08/25",
        "duration": "0:08",
        "imagePath": "images/project-card.png",
        "status": "Completed",
      },
      {
        "title": "Marketing Promo",
        "createdDate": "8/08/25",
        "duration": "0:15",
        "imagePath": "images/project-card.png",
        "status": "Draft",
      },
      {
        "title": "Product Demo",
        "createdDate": "7/08/25",
        "duration": "0:30",
        "imagePath": "images/project-card.png",
        "status": "Completed",
      },
      {
        "title": "Tutorial Video",
        "createdDate": "6/08/25",
        "duration": "1:20",
        "imagePath": "images/project-card.png",
        "status": "Completed",
      },
      {
        "title": "Company Intro",
        "createdDate": "5/08/25",
        "duration": "0:45",
        "imagePath": "images/project-card.png",
        "status": "Draft",
      },
      {
        "title": "Social Media Ad",
        "createdDate": "4/08/25",
        "duration": "0:12",
        "imagePath": "images/project-card.png",
        "status": "Completed",
      },
    ];

    if (projects.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        int crossAxisCount = 2;
        if (isTablet) {
          crossAxisCount = isLandscape ? 4 : 3;
        } else if (isLandscape) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              title: project['title']!,
              createdDate: project['createdDate']!,
              duration: project['duration']!,
              imagePath: project['imagePath']!,
              onPlay: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Playing ${project['title']}"),
                    backgroundColor: Colors.green,
                  ),
                );
              },

              onDownload: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Downloading ${project['title']}"),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              onDelete: () {
                _showDeleteConfirmation(context, project['title']!);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Projects Found",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first video project to get started",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          RoundButton(
            title: "Create Your First Project",
            onPress: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Create project feature coming soon!"),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            leadingIcon: Icons.add,
            leadingIconColor: Colors.white,
            bgColor: AppColors.purpleColor,
            borderRadius: 12,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        title: const Text(
          "Delete Project",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete '$projectName'? This action cannot be undone.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Project deleted successfully!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
