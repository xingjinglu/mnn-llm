//
//  LLMInferenceEngineWrapper.m
//  mnn-llm
//
//  Created by wangzhaode on 2023/12/14.
//

#import "LLMInferenceEngineWrapper.h"
#include "llm.hpp"

const char* GetMainBundleDirectory() {
    NSString *bundleDirectory = [[NSBundle mainBundle] bundlePath];
    return [bundleDirectory UTF8String];
}

@implementation LLMInferenceEngineWrapper {
    Llm* llm;
}

- (instancetype)initWithCompletionHandler:(ModelLoadingCompletionHandler)completionHandler {
    self = [super init];
    if (self) {
        // 在后台线程异步加载模型
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL success = [self loadModel]; // 假设loadModel方法加载模型并返回加载的成功或失败
            // 切回主线程回调
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success);
            });
        });
    }
    return self;
}
void SearchFiles(){
    NSString *homeDirectory = NSHomeDirectory();
    NSLog(@"Home Directory: %@", homeDirectory);
    // 获取应用程序的Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    // 使用NSFileManager获取Documents目录下的所有文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:homeDirectory error:&error];

    if (directoryContents) {
        // 遍历目录内容，查找特定文件
        NSString *searchFileName = @"config.json";
        BOOL fileFound = NO;
        
        for (NSString *fileName in directoryContents) {
            if ([fileName isEqualToString:searchFileName]) {
                fileFound = YES;
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
                NSLog(@"File found at path: %@", filePath);
                break;
            }
        }
        
        if (!fileFound) {
            NSLog(@"File not found: %@", searchFileName);
        }
    } else {
        NSLog(@"Error reading directory contents: %@", error);
    }
}

void FindFiles(){
    NSBundle *mainBundle = [NSBundle mainBundle];

    NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
    NSLog(@"Main bundle path: %@", mainBundlePath);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 创建一个NSError对象来捕获错误
    NSError *error;

    // 获取目录内容
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:mainBundlePath error:&error];

    // 检查是否有错误
    if (error) {
        NSLog(@"Error getting directory contents: %@", [error localizedDescription]);
    } else {
        // 遍历目录内容
        for (NSString *path in directoryContents) {
            NSString *fullPath = [mainBundlePath stringByAppendingPathComponent:path];
            NSLog(@"Found file: %@", fullPath);
        }
    }
    
}

- (BOOL)loadModel {
    if (!llm) {
        
        NSString *homeDirectory = NSHomeDirectory();
        NSLog(@"Home Directory: %@", homeDirectory);
        
        
        /*
        // 获取Documents目录路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //NSString *documentsDirectory = [paths firstObject];

        // 获取Caches目录路径
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths firstObject];

        // 获取tmp目录路径
        NSString *tmpDirectory = NSTemporaryDirectory();

        // 获取Application Support目录路径
        paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *appSupportDirectory = [paths firstObject];
        
        //NSLog(@"documentsDirectory path: %@", documentsDirectory);
        NSLog(@"cachesDirectory path: %@", cachesDirectory);
        NSLog(@"tmpDirectory path: %@", tmpDirectory);
        NSLog(@"appSupportDirectory path: %@", appSupportDirectory);
        
        */
        
        // 获取main bundle的路径
        NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
        NSLog(@"Main bundle path: %@", mainBundlePath);
        
        
        /*
        
        */
        FindFiles();
        SearchFiles();
        
        // 获取Documents目录的路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //NSString *documentsDirectory = [paths firstObject];
       

        //std::string model_dir = GetMainBundleDirectory();
        /*
        const char *cModelDir = [documentsDirectory UTF8String];
        std::string model_dir = std::string(cModelDir);
        model_dir = model_dir + "/config.json";
        //model_dir = model_dir + "/qwen-1.8b";

        NSString *model_dir_ns = [NSString stringWithUTF8String:model_dir.c_str()];

        NSLog(@"model_dir: %@", model_dir_ns);
        */
       
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, //NSUserDomainMask, YES);
       
        NSString *filePath = [mainBundlePath stringByAppendingPathComponent:@"config.json"];
        NSLog(@"Find File Path: %@", filePath);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSLog(@"File exists");
        } else {
            NSLog(@"File does not exist: %@", filePath);
        }
        
        NSString *model_dir_ns = filePath;
        const char *cModelDir = [model_dir_ns UTF8String];
        std::string model_dir = std::string(cModelDir);
        
        
        // 检查读权限
       
        
        if ([fileManager isReadableFileAtPath:model_dir_ns]) {
            NSLog(@"File is readable");
        } else {
            NSLog(@"File is not readable");
        }
        
        llm = Llm::createLLM(model_dir);
        NSLog(@"after createLLM");
        llm->load();
    }
    return YES;
}

- (void)processInput:(NSString *)input withStreamHandler:(StreamOutputHandler)handler {
    LlmStreamBuffer::CallBack callback = [handler](const char* str, size_t len) {
        if (handler) {
            NSString *nsOutput = [NSString stringWithUTF8String:str];
            handler(nsOutput);
        }
    };
    LlmStreamBuffer streambuf(callback);
    std::ostream os(&streambuf);
    llm->response([input UTF8String], &os, "<eop>");
}

- (void)dealloc {
    delete llm;
}
@end
