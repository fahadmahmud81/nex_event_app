import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NoticePage extends StatefulWidget {
  @override
  _NoticePageState createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  void _deleteNotice(String noticeId) async {
    final confirmed = await _showConfirmationDialog(
      context,
      "Delete Notice",
      "Are you sure you want to delete this notice?",
    );
    if (confirmed) {
      try {
        await FirebaseFirestore.instance.collection('notice').doc(noticeId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notice: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: Text("Confirm"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _updateNotice(String noticeId, String currentTitle, String currentDescription,
      String currentDate, String currentType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoticePage(
          noticeId: noticeId,
          initialTitle: currentTitle,
          initialDescription: currentDescription,
          initialDate: currentDate,
          initialType: currentType,
        ),
      ),
    );

    if (result != null && result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notice updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateNoticePage()),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Aligns the header to the start
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10), // Adds some space around the title
            child: Text(
              "Notice Board For Students",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notice').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final notices = snapshot.data!.docs;

                if (notices.isEmpty) {
                  return Center(child: Text("No notices available"));
                }

                return ListView.builder(
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final noticeId = notice.id;
                    final title = notice['Title'];
                    final description = notice['Description'];
                    final date = notice['Date'];
                    final type = notice['NoticeType'];

                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text("Date: $date | Type: $type"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _updateNotice(noticeId, title, description, date, type),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNotice(noticeId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class CreateNoticePage extends StatefulWidget {
  final String? noticeId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialDate;
  final String? initialType;

  CreateNoticePage({
    this.noticeId,
    this.initialTitle,
    this.initialDescription,
    this.initialDate,
    this.initialType,
  });

  @override
  _CreateNoticePageState createState() => _CreateNoticePageState();
}

class _CreateNoticePageState extends State<CreateNoticePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedDate = "";
  String _noticeType = "Ads";

  @override
  void initState() {
    super.initState();
    if (widget.noticeId != null) {
      _titleController.text = widget.initialTitle ?? "";
      _descriptionController.text = widget.initialDescription ?? "";
      _selectedDate = widget.initialDate ?? "";
      _noticeType = widget.initialType ?? "Ads";
    }
  }

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  void _saveNotice() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      final notice = {
        "Title": _titleController.text,
        "Description": _descriptionController.text,
        "Date": _selectedDate,
        "NoticeType": _noticeType,
      };

      try {
        if (widget.noticeId == null) {
          // Create new notice
          String noticeId = DateTime.now().millisecondsSinceEpoch.toString();
          await FirebaseFirestore.instance.collection('notice').doc(noticeId).set(notice);
        } else {
          // Update existing notice
          await FirebaseFirestore.instance.collection('notice').doc(widget.noticeId).update(notice);
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noticeId == null ? "Create Notice" : "Update Notice"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title" ,border:
                    OutlineInputBorder(),), // Adds a border around the text field),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15,),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Description",   border:
                OutlineInputBorder(), // Adds a border around the text field
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                maxLines: 5,
              ),
              SizedBox(height: 15,),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _selectedDate.isEmpty
                          ? "Select Date"
                          : "Date: $_selectedDate",
                      suffixIcon: Icon(Icons.calendar_today),
                      border:
                      OutlineInputBorder(), // Adds a border around the text field
                    ),
                    validator: (value) {
                      if (_selectedDate.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 15,),
              DropdownButtonFormField<String>(
                value: _noticeType,
                decoration: InputDecoration(labelText: "Notice Type"),
                items: ["Ads", "SuperAdmin"].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _noticeType = value!;
                  });
                },
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saveNotice,
                child: Text(widget.noticeId == null ? "Create Notice" : "Update Notice"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

