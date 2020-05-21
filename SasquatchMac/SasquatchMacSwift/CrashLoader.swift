// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Foundation

class CrashLoader {
    public static func loadAllCrashes(withCategories appendCategories: Bool = true) -> [Any] {
        var resultCrashes = [Any]()
        pokeAllCrashes()
        var sortedCrashes = MSCrash.allCrashes() as! [MSCrash]
        sortedCrashes = sortedCrashes.sorted { (crash1, crash2) -> Bool in
            if crash1.category == crash2.category {
                return crash1.title > crash2.title
            } else {
                return crash1.category < crash2.category
            }
        }
        if sortedCrashes.count > 0 {
            var currentCategory = sortedCrashes[0].category!
            if (appendCategories) {
                resultCrashes.append(currentCategory as Any)
            }
            for crash in sortedCrashes {
                if (appendCategories) {
                    if currentCategory != crash.category {
                        currentCategory = crash.category
                        resultCrashes.append(currentCategory as Any)
                    }
                }
                resultCrashes.append(crash as Any)
            }
        }
        return resultCrashes
    }
    
    private static func pokeAllCrashes() {
      var count = UInt32(0)
      let classList = objc_copyClassList(&count)
      let classes = UnsafeBufferPointer(start: classList, count: Int(count))
      MSCrash.removeAllCrashes()
      for i in 0..<Int(count){
        let className: AnyClass = classes[i]
        if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
          MSCrash.register((className as! MSCrash.Type).init())
        }
      }
    }
}
