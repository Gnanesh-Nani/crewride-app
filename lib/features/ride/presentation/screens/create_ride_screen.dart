import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crewride_app/core/network/dio_client.dart';
import 'package:crewride_app/core/constants/endpoints/ride_endpoints.dart';

class CreateRideScreen extends StatefulWidget {
  @override
  _CreateRideScreenState createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _visibility = 'public';
  DateTime? _startTime;
  DateTime? _endTime;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select start and end times.')),
        );
        return;
      }

      final rideData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'visibility': _visibility,
        // Use UTC ISO strings to match backend expectations
        'startTime': _startTime!.toUtc().toIso8601String(),
        'endTime': _endTime!.toUtc().toIso8601String(),
      };

      try {
        final response = await DioClient.instance.post(
          RideEndpoints.createRide,
          data: rideData,
        );

        if (response.data['error'] == false) {
          // Extract created ride id from backend response and pass it
          final createdRide = response.data['data']?['ride'];
          final rideId = createdRide != null
              ? createdRide['id']?.toString()
              : null;

          final waypointArgs = Map<String, dynamic>.from(rideData);
          if (rideId != null) waypointArgs['id'] = rideId;

          // Navigate to waypoint selection page. After waypoint selection
          // finishes, return `true` to the caller (e.g. MapScreen) so it can refresh.
          await Navigator.pushNamed(
            context,
            '/waypointSelection',
            arguments: waypointArgs,
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'Failed to create ride.',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating ride: $e')));
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: InputDecoration(labelText: 'Visibility'),
                items: [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) {
                  setState(() {
                    _visibility = value!;
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDateTime(context, true),
                      child: Text(
                        _startTime == null
                            ? 'Select Start Time'
                            : DateFormat.yMd().add_jm().format(_startTime!),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDateTime(context, false),
                      child: Text(
                        _endTime == null
                            ? 'Select End Time'
                            : DateFormat.yMd().add_jm().format(_endTime!),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: Text('Next')),
            ],
          ),
        ),
      ),
    );
  }
}
