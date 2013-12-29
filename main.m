#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kPresetName AVAssetExportPresetAppleM4V480pSD
#define kFileType AVFileTypeAppleM4V
#define kFileExtension @"mov"

int main(int argc, const char* argv[]) {
  if (argc != 2) {
    return 1;
  }
  @autoreleasepool {
    NSString* path = [NSString stringWithUTF8String:argv[1]];
    for (NSString* file in [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
      if ([file hasPrefix:@"."] || [[file pathExtension] length]) {
        continue;
      }
      @autoreleasepool {
        NSString* inPath = [path stringByAppendingPathComponent:file];
        NSString* outPath = [inPath stringByAppendingPathExtension:kFileExtension];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:outPath]) {
          printf("Processing \"%s\"\n", [inPath UTF8String]);
          AVAsset* asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:inPath]];
          AVAssetExportSession* session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:kPresetName];
          session.outputFileType = kFileType;
          session.outputURL = [NSURL fileURLWithPath:outPath];
          [session exportAsynchronouslyWithCompletionHandler:^{
            
            printf("\n");
            if (session.error) {
              printf("<ERROR> %s\n", [[session.error description] UTF8String]);
            }
            CFRunLoopStop(CFRunLoopGetMain());
            
          }];
          
          __block float lastProgress = 0.0;
          CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, 0.0, 1.0, 0, 0, ^(CFRunLoopTimerRef timer) {
            @autoreleasepool {
              float newProgress = session.progress;
              if (floorf(newProgress * 100.0) > floorf(lastProgress * 100.0)) {
                for (int i = 0, max = floorf(newProgress * 100.0) - floorf(lastProgress * 100.0); i < max; ++i) {
                  printf(".");
                }
                fflush(stdout);
                lastProgress = newProgress;
              }
            }
          });
          CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);
          CFRunLoopRun();
          CFRunLoopTimerInvalidate(timer);
          CFRelease(timer);
        } else {
          printf("<SKIPPING \"%s\">\n", [inPath UTF8String]);
        }
        
      }
    }
  }
  return 0;
}
