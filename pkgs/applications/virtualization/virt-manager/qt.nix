{ mkDerivation, lib, fetchFromGitHub, cmake, pkgconfig
, qtbase, qtmultimedia, qtsvg, qttools, krdc
, libvncserver, libvirt, pcre, pixman, qtermwidget, spice-gtk, spice-protocol
}:

mkDerivation rec {
  name = "virt-manager-qt-${version}";
  version = "0.70.90";

  src = fetchFromGitHub {
    owner  = "F1ash";
    repo   = "qt-virt-manager";
    rev    = "${version}";
    sha256 = "0zfsrrdh18blr52j5jvgkxr1ngwcn14716rxbmy344851rs9ldch";
  };

  cmakeFlags = [
    "-DBUILD_QT_VERSION=5"
    "-DQTERMWIDGET_INCLUDE_DIRS=${qtermwidget}/include/qtermwidget5"
  ];

  buildInputs = [
    qtbase qtmultimedia qtsvg krdc
    libvirt libvncserver pcre pixman qtermwidget spice-gtk spice-protocol
  ];

  nativeBuildInputs = [ cmake pkgconfig qttools ];

  meta = with lib; {
    homepage    = https://f1ash.github.io/qt-virt-manager;
    description = "Desktop user interface for managing virtual machines (QT)";
    longDescription = ''
      The virt-manager application is a desktop user interface for managing
      virtual machines through libvirt. It primarily targets KVM VMs, but also
      manages Xen and LXC (linux containers).
    '';
    license     = licenses.gpl2;
    maintainers = with maintainers; [ peterhoeg ];
    inherit (qtbase.meta) platforms;
  };
}
