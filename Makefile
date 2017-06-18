# Created by: Jov <amutu@amutu.com>
# $FreeBSD$

PORTNAME=	tensorflow
PORTVERSION=	1.1.0
DISTVERSIONPREFIX=	v
CATEGORIES=	science python
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	amutu@amutu.com
COMMENT=	Computation using data flow graphs for scalable machine learning

LICENSE=	APACHE20

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}wheel>=0.29.0:devel/py-wheel \
		${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy \
		bash:shells/bash
RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy \
		${PYTHON_PKGNAMEPREFIX}protobuf>=3.2.0:devel/py-protobuf

USE_GITHUB=	yes
USES=		python:2.7+ shebangfix
BAZEL_BOOT=	--output_user_root=${WRKDIR}/bazel_ot --batch
BAZEL_COPT=

SHEBANG_LANG=	python
python_OLD_CMD=	"/usr/bin/env python"
SHEBANG_GLOB=	*.py

.include <bsd.port.pre.mk>

.if ${OSREL:C/\..*//} == "10"
BUILD_DEPENDS+=	bazel:devel/bazel_clang38
.else
BUILD_DEPENDS+=	bazel:devel/bazel
.endif

#clang has this check enabled by default,disable it
#see: https://github.com/tensorflow/tensorflow/issues/8894
.if ${ARCH} == "i386"
BAZEL_COPT+=	--copt=-Wno-c++11-narrowing
.endif

do-patch:
	${REINPLACE_CMD} "s#bazel \([cf]\)#bazel ${BAZEL_BOOT} \1#g" ${WRKSRC}/configure

do-configure:
	(cd ${WRKSRC} && ${SETENV} \
		PYTHON_BIN_PATH=${PYTHON_CMD} \
	       	TF_NEED_MKL=N \
		CC_OPT_FLAGS="${CFLAGS}" \
		TF_NEED_GCP=N TF_NEED_HDFS=N \
		TF_ENABLE_XLA=N \
	       	TF_NEED_OPENCL=N \
		TF_NEED_CUDA=N \
		PYTHON_LIB_PATH="${PYTHON_SITELIBDIR}" \
	       	./configure)
	(cd ${WRKDIR}/bazel_ot/[^i]*/ && \
	${REINPLACE_CMD} -e 's/\([ :]\)m\(..\)or(/\1_m\2or(/g' \
	external/protobuf/src/google/protobuf/compiler/plugin.pb.h && \
	${REINPLACE_CMD} -e 's/->m\(..\)or(/->_m\1or(/g' \
	-e 's/\([.:]\)m\(..\)or(/\1_m\2or(/g' \
	external/protobuf/src/google/protobuf/compiler/plugin.pb.cc && \
	${REINPLACE_CMD} -e 's/#define GPR_HAVE_IP_PKTINFO 1/\/\/&/' \
	external/grpc/include/grpc/impl/codegen/port_platform.h)

do-build:
	(cd ${WRKSRC} && bazel ${BAZEL_BOOT} build ${BAZEL_COPT} --config=opt \
		//tensorflow/tools/pip_package:build_pip_package --verbose_failures)
	(cd ${WRKSRC} && ${SETENV} TMPDIR=${WRKDIR} \
	      	bazel-bin/tensorflow/tools/pip_package/build_pip_package \
		${WRKDIR}/whl)

do-install:
	${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}
	${MKDIR} ${WRKDIR}/tmp
	${UNZIP_NATIVE_CMD} -d ${WRKDIR}/tmp ${WRKDIR}/whl/${PORTNAME}-${PORTVERSION}-*.whl
	cd ${WRKDIR}/tmp && ${COPYTREE_SHARE} ${PORTNAME}-${PORTVERSION}.dist-info \
		${STAGEDIR}${PYTHON_SITELIBDIR}
	cd ${WRKDIR}/tmp/${PORTNAME}-${PORTVERSION}.data/purelib && \
		${COPYTREE_SHARE} . ${STAGEDIR}${PYTHON_SITELIBDIR}

.include <bsd.port.post.mk>
