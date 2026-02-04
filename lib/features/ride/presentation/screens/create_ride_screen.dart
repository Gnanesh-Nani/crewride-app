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
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end times.')),
        );
        return;
      }

      if (_endTime!.isBefore(_startTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      setState(() => _isLoading = true);

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
          final createdRide = response.data['data']?['ride'];
          final rideId = createdRide != null
              ? createdRide['id']?.toString()
              : null;

          final waypointArgs = Map<String, dynamic>.from(rideData);
          if (rideId != null) waypointArgs['id'] = rideId;

          if (mounted) {
            await Navigator.pushNamed(
              context,
              '/waypointSelection',
              arguments: waypointArgs,
            );
            if (mounted) Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response.data['message'] ?? 'Failed to create ride.',
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_startTime ?? DateTime.now())
          : (_endTime ?? DateTime.now()),
      firstDate: DateTime.now(),
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
      appBar: AppBar(title: const Text('Create Ride'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title section
              const Text(
                'Ride Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Ride Title',
                  hintText: 'e.g., Weekend City Ride',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell riders about this ride...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Visibility section
              const Text(
                'Visibility',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.visibility),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: [
                  DropdownMenuItem(
                    value: 'public',
                    child: Row(
                      children: const [
                        Icon(Icons.public, size: 20),
                        SizedBox(width: 8),
                        Text('Public'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Row(
                      children: const [
                        Icon(Icons.lock, size: 20),
                        SizedBox(width: 8),
                        Text('Private'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _visibility = value!);
                },
              ),
              const SizedBox(height: 20),

              // Date & Time section
              const Text(
                'Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Start time
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: Colors.green),
                  title: const Text('Start Time'),
                  subtitle: Text(
                    _startTime == null
                        ? 'Select start time'
                        : DateFormat(
                            'MMM dd, yyyy - HH:mm',
                          ).format(_startTime!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _startTime == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateTime(context, true),
                ),
              ),
              const SizedBox(height: 12),

              // End time
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: Colors.red),
                  title: const Text('End Time'),
                  subtitle: Text(
                    _endTime == null
                        ? 'Select end time'
                        : DateFormat('MMM dd, yyyy - HH:mm').format(_endTime!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _endTime == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDateTime(context, false),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _isLoading ? 'Creating Ride...' : 'Continue to Waypoints',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
