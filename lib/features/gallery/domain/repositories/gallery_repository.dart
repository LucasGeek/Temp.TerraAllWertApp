import 'dart:typed_data';
import '../entities/gallery_image.dart';
import '../entities/image_pin.dart';

abstract class GalleryRepository {
  Future<List<GalleryImage>> getImagesByApartment(String apartmentId);
  Future<GalleryImage?> getImageById(String id);
  Future<GalleryImage> createImage(GalleryImage image);
  Future<GalleryImage> updateImage(GalleryImage image);
  Future<void> deleteImage(String id);
  Future<String> uploadImage({
    required String apartmentId,
    required String fileName,
    required Uint8List imageData,
    String? title,
    String? description,
  });
  Future<List<ImagePin>> getImagePins(String imageId);
  Future<ImagePin> createImagePin(ImagePin pin);
  Future<ImagePin> updateImagePin(ImagePin pin);
  Future<void> deleteImagePin(String id);
  Future<void> syncImages();
  Stream<List<GalleryImage>> watchImagesByApartment(String apartmentId);
  Stream<List<ImagePin>> watchImagePins(String imageId);
}