import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Image'),
                backgroundColor: Colors.orange.shade700,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  progressIndicatorBuilder: (context, url, downloadProgress) => 
                    Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load image: $error', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }