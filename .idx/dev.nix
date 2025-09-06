{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = [
    pkgs.jdk17
    pkgs.unzip
  ];

  env = {};

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    previews = {
      enable = true;

      previews = {
        web = {
          command = [
            "flutter" "run"
            "--machine"
            "-d" "web-server"
            "--web-hostname" "0.0.0.0"
            "--web-port" "$PORT"
          ];
          manager = "flutter";
          cwd = "."; # O "sistema_ventas" si tu pubspec.yaml está dentro de esa carpeta
        };

        android = {
          command = [
            "flutter" "run"
            "--machine"
            "-d" "web-server"
            "--web-hostname" "0.0.0.0"
            "--web-port" "3000"
          ];
          manager = "flutter";
          cwd = "."; # O "sistema_ventas" según tu estructura
        };
      };
    };
  };
}
