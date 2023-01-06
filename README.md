# IDDList

This is a custom made SwiftUI.List clone with all the source code to go with it.
It has benefits and can be used as a full table column.
It is a wrapper to the fantastic NSTableView.
It supports macOS 11 and above.

It is able to handle a giant amount of rows, 500k with no problem. Take that SwiftUI.List
However we have discovered that Array<V>.sort(by: keyPath) is 6 to 7 time slower than using pure functions

There are 2 example target in the package. 

**MacTableView** is build using Vanilla SwiftUI and 

**TCATableView** is built using the TCA store from https://pointfree.co

https://user-images.githubusercontent.com/43558687/156873789-3e4217cd-548b-4a4c-858f-e173c35286f3.mov

