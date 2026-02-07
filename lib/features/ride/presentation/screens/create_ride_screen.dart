import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crewride_app/core/network/dio_client.dart';
import 'package:crewride_app/core/constants/endpoints/ride_endpoints.dart';
import 'package:crewride_app/features/home/data/ride_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

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

  late final String _osrmUrl = dotenv.env['OSRM_URL'] ?? '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _calculateRoute(
    List<Map<String, dynamic>> waypoints,
  ) async {
    try {
      if (waypoints.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 2 waypoints')),
        );
        return null;
      }

      // Sort waypoints by orderIndex
      final sortedWaypoints = List.of(waypoints);
      sortedWaypoints.sort(
        (a, b) => (a['orderIndex'] ?? 0).compareTo(b['orderIndex'] ?? 0),
      );

      // Create coordinates string for OSRM: longitude,latitude;longitude,latitude;...
      final coords = sortedWaypoints
          .map((w) => '${w['longitude']},${w['latitude']}')
          .join(';');
      final url = '$_osrmUrl/$coords?overview=full&geometries=geojson';

      final dio = Dio();
      final res = await dio.get(url);

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
          final distance = (routes[0]['distance'] as num?)?.toDouble() ?? 0.0;

          if (geometry != null && geometry['coordinates'] is List) {
            final coordsList = geometry['coordinates'] as List<dynamic>;

            // Create GeoJSON LineString
            final routePath = {
              'type': 'LineString',
              'coordinates': coordsList.map((c) {
                return [(c[0] as num).toDouble(), (c[1] as num).toDouble()];
              }).toList(),
            };

            return {'routePath': routePath, 'distanceMeters': distance};
          }
        }
      }
      return null;
    } catch (e) {
      print('Route calculation error: $e');
      return null;
    }
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
        'startTime': _startTime!.toUtc().toIso8601String(),
        'endTime': _endTime!.toUtc().toIso8601String(),
      };

      try {
        if (mounted) {
          // Navigate to waypoint selection and wait for waypoints
          final waypoints =
              await Navigator.pushNamed(
                    context,
                    '/waypointSelection',
                    arguments: rideData,
                  )
                  as List<Map<String, dynamic>>?;

          if (waypoints != null && waypoints.isNotEmpty && mounted) {
            // Calculate route
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Calculating route...'),
                duration: Duration(seconds: 2),
              ),
            );

            final routeData = await _calculateRoute(waypoints);

            if (mounted) {
              if (routeData != null) {
                try {
                  // Prepare complete ride data with route
                  final completeRideData = {
                    ...rideData,
                    'distanceMeters': (routeData['distanceMeters'] as double)
                        .toInt(),
                    'routePath': routeData['routePath'],
                  };

                  // Create ride with route data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Creating ride...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  final createResponse = await DioClient.instance.post(
                    RideEndpoints.createRide,
                    data: completeRideData,
                  );

                  if (mounted) {
                    if (createResponse.data['error'] == false) {
                      final createdRide = createResponse.data['data']?['ride'];
                      final rideId = createdRide != null
                          ? createdRide['id']?.toString()
                          : null;

                      if (rideId != null) {
                        // Now save waypoints to the created ride
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving waypoints...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        final api = RideApi();
                        final waypointResponse = await api.addWaypoints(
                          rideId,
                          waypoints,
                        );

                        if (mounted) {
                          if (waypointResponse.statusCode! >= 200 &&
                              waypointResponse.statusCode! < 300) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ride created successfully with waypoints!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  waypointResponse.data?['message'] ??
                                      'Failed to save waypoints',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create ride'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            createResponse.data['message'] ??
                                'Failed to create ride',
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
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not calculate route. Try again.'),
                  ),
                );
              }
            }
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
              Text(
                'Ride Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
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
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey[50],
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
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey[50],
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
              Text(
                'Visibility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.visibility),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey[50],
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
              Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Start time
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey[300]!,
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey[50],
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
                      color: _startTime == null
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[500]
                                : Colors.grey)
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87),
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
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey[300]!,
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey[50],
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
                      color: _endTime == null
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[500]
                                : Colors.grey)
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
