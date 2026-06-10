import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';

class LocationScreen extends StatelessWidget {
	const LocationScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final provider = Provider.of<LocationProvider>(context);

		return Scaffold(
			appBar: AppBar(
				title: const Text('My Location'),
			),
			body: Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						ElevatedButton(
							onPressed: () async {
								await provider.getCurrentLocation();
							},
							child: const Text('Get Current Location'),
						),
						const SizedBox(height: 20),
						Text('Latitude: ${provider.latitude ?? 'Not Available'}'),
						Text('Longitude: ${provider.longitude ?? 'Not Available'}'),
					],
				),
			),
		);
	}
}

