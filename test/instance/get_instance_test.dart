// ignore_for_file: avoid_classes_with_only_static_members, cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:refreshed/refreshed.dart";

import "util/matcher.dart" as m;

abstract class MyController with GetLifeCycleMixin {}

class DisposableController extends MyController {}

// ignore: one_member_abstracts
abstract class Service {}

class Api implements Service {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("Get.put test", () async {
    final Controller instance = Get.put<Controller>(Controller());
    expect(instance, Get.find<Controller>());
    Get.reset();
  });

  test("Get start and delete called just one time", () async {
    Get
      ..put(Controller())
      ..put(Controller());

    final Controller controller = Get.find<Controller>();
    expect(controller.init, 1);

    Get
      ..delete<Controller>()
      ..delete<Controller>();
    expect(controller.close, 1);
    Get.reset();
  });

  test("Get.put tag test", () async {
    final Controller instance = Get.put<Controller>(Controller(), tag: "one");
    final Controller instance2 = Get.put(Controller(), tag: "two");
    expect(instance == instance2, false);
    expect(
      Get.find<Controller>(tag: "one") == Get.find<Controller>(tag: "two"),
      false,
    );
    expect(
      Get.find<Controller>(tag: "one") == Get.find<Controller>(tag: "one"),
      true,
    );
    expect(
      Get.find<Controller>(tag: "two") == Get.find<Controller>(tag: "two"),
      true,
    );
    Get.reset();
  });

  test("Get.lazyPut tag test", () async {
    Get.lazyPut<Controller>(Controller.new, tag: "one");
    Get.lazyPut<Controller>(Controller.new, tag: "two");

    expect(
      Get.find<Controller>(tag: "one") == Get.find<Controller>(tag: "two"),
      false,
    );
    expect(
      Get.find<Controller>(tag: "one") == Get.find<Controller>(tag: "one"),
      true,
    );
    expect(
      Get.find<Controller>(tag: "two") == Get.find<Controller>(tag: "two"),
      true,
    );
    Get.reset();
  });

  test("Get.lazyPut test", () async {
    final Controller controller = Controller();
    Get.lazyPut<Controller>(() => controller);
    final Controller ct1 = Get.find<Controller>();
    expect(ct1, controller);
    Get.reset();
  });

  test("Get.lazyPut fenix test", () async {
    Get.lazyPut<Controller>(Controller.new, fenix: true);
    Get.find<Controller>().increment();

    expect(Get.find<Controller>().count, 1);
    Get.delete<Controller>();
    expect(Get.find<Controller>().count, 0);
    Get.reset();
  });

  test("Get.lazyPut without fenix", () async {
    Get.lazyPut<Controller>(Controller.new);
    Get.find<Controller>().increment();

    expect(Get.find<Controller>().count, 1);
    Get.delete<Controller>();
    expect(
      () => Get.find<Controller>(),
      throwsA(const m.TypeMatcher<Exception>()),
    );
    Get.reset();
  });

  test("Get.reloadInstance test", () async {
    Get.lazyPut<Controller>(Controller.new);
    Controller ct1 = Get.find<Controller>();
    ct1.increment();
    expect(ct1.count, 1);
    ct1 = Get.find<Controller>();
    expect(ct1.count, 1);
    Get.reload<Controller>();
    ct1 = Get.find<Controller>();
    expect(ct1.count, 0);
    Get.reset();
  });

  test("GetxService test", () async {
    Get.lazyPut<PermanentService>(PermanentService.new);
    final PermanentService sv1 = Get.find<PermanentService>();
    final PermanentService sv2 = Get.find<PermanentService>();
    expect(sv1, sv2);
    expect(Get.isRegistered<PermanentService>(), true);
    Get.delete<PermanentService>();
    expect(Get.isRegistered<PermanentService>(), true);
    Get.delete<PermanentService>(force: true);
    expect(Get.isRegistered<PermanentService>(), false);
    Get.reset();
  });

  test("Get.lazyPut with abstract class test", () async {
    final Api api = Api();
    Get.lazyPut<Service>(() => api);
    final Service ct1 = Get.find<Service>();
    expect(ct1, api);
    Get.reset();
  });

  test("Get.create with abstract class test", () async {
    Get.spawn<Service>(Api.new);
    final Service ct1 = Get.find<Service>();
    final Service ct2 = Get.find<Service>();
    // expect(ct1 is Service, true);
    // expect(ct2 is Service, true);
    expect(ct1 == ct2, false);
    Get.reset();
  });

  group("test put, delete and check onInit execution", () {
    tearDownAll(Get.reset);

    test("Get.put test with init check", () async {
      final DisposableController instance = Get.put(DisposableController());
      expect(instance, Get.find<DisposableController>());
      expect(instance.initialized, true);
    });

    test("Get.delete test with disposable controller", () async {
      expect(Get.delete<DisposableController>(), true);
      expect(
        () => Get.find<DisposableController>(),
        throwsA(const m.TypeMatcher<Exception>()),
      );
    });

    test("Get.put test after delete with disposable controller and init check",
        () async {
      final DisposableController instance =
          Get.put<DisposableController>(DisposableController());
      expect(instance, Get.find<DisposableController>());
      expect(instance.initialized, true);
    });
  });

  group("Get.replace test for replacing parent instance that is", () {
    tearDown(Get.reset);
    test("temporary", () async {
      Get.put(DisposableController());
      Get.replace<DisposableController>(Controller());
      final DisposableController instance = Get.find<DisposableController>();
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test("permanent", () async {
      Get.put(DisposableController(), permanent: true);
      Get.replace<DisposableController>(Controller());
      final DisposableController instance = Get.find<DisposableController>();
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test("tagged temporary", () async {
      const String tag = "tag";
      Get.put(DisposableController(), tag: tag);
      Get.replace<DisposableController>(Controller(), tag: tag);
      final DisposableController instance =
          Get.find<DisposableController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test("tagged permanent", () async {
      const String tag = "tag";
      Get.put(DisposableController(), permanent: true, tag: tag);
      Get.replace<DisposableController>(Controller(), tag: tag);
      final DisposableController instance =
          Get.find<DisposableController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test("a generic parent type", () async {
      const String tag = "tag";
      Get.put<MyController>(DisposableController(), permanent: true, tag: tag);
      Get.replace<MyController>(Controller(), tag: tag);
      final MyController instance = Get.find<MyController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });
  });

  group("Get.lazyReplace replaces parent instance", () {
    tearDown(Get.reset);
    test("without fenix", () async {
      Get.put(DisposableController());
      Get.lazyReplace<DisposableController>(Controller.new);
      final DisposableController instance = Get.find<DisposableController>();
      expect(instance, isA<Controller>());
      expect((instance as Controller).init, greaterThan(0));
    });

    test("with fenix", () async {
      Get.put(DisposableController());
      Get.lazyReplace<DisposableController>(Controller.new, fenix: true);
      expect(Get.find<DisposableController>(), isA<Controller>());
      (Get.find<DisposableController>() as Controller).increment();

      expect((Get.find<DisposableController>() as Controller).count, 1);
      Get.delete<DisposableController>();
      expect((Get.find<DisposableController>() as Controller).count, 0);
    });

    test("with fenix when parent is permanent", () async {
      Get.put(DisposableController(), permanent: true);
      Get.lazyReplace<DisposableController>(Controller.new);
      final DisposableController instance = Get.find<DisposableController>();
      expect(instance, isA<Controller>());
      (instance as Controller).increment();

      expect((Get.find<DisposableController>() as Controller).count, 1);
      Get.delete<DisposableController>();
      expect((Get.find<DisposableController>() as Controller).count, 0);
    });
  });

  group("Get.findOrNull test", () {
    tearDown(Get.reset);
    test("checking results", () async {
      Get.put<int>(1);
      int? result = Get.findOrNull<int>();
      expect(result, 1);

      Get.delete<int>();
      result = Get.findOrNull<int>();
      expect(result, null);
    });
  });
}

class PermanentService extends GetxService {}

class Controller extends DisposableController {
  int init = 0;
  int close = 0;
  int count = 0;
  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }

  void increment() {
    count++;
  }
}
