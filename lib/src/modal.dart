// part of 'engine.dart';
//
// /// Tracks the listener widgets and notify them when
// /// their corresponding action executes
// class _DataFlowModel extends InheritedModel {
//   final Set<Type>? recent;
//
//   const _DataFlowModel({required super.child, this.recent});
//
//   @override
//   bool updateShouldNotify(covariant InheritedWidget oldWidget) =>
//       oldWidget.hashCode != recent.hashCode;
//
//   @override
//   bool updateShouldNotifyDependent(covariant InheritedModel oldWidget, Set dependencies) {
//     // check if there is a mutation executed for which
//     // dependent has listened
//     return dependencies.intersection(recent!).isNotEmpty;
//   }
// }
