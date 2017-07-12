# Created by: Jov <amutu@amutu.com>
# $FreeBSD$

PORTNAME=	tensorflow
PORTVERSION=	1.2.0
DISTVERSIONPREFIX=	v
CATEGORIES=	science python
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	amutu@amutu.com
COMMENT=	Computation using data flow graphs for scalable machine learning

LICENSE=	APACHE20

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}wheel>=0.29.0:devel/py-wheel \
		${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy \
		bash:shells/bash \
		bazel:devel/bazel_clang38
RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}numpy>=1.11.2:math/py-numpy \
		${PYTHON_PKGNAMEPREFIX}markdown>=2.2.0:textproc/py-markdown \
		${PYTHON_PKGNAMEPREFIX}bleach>=1.4.2:www/py-bleach \
		${PYTHON_PKGNAMEPREFIX}html5lib>=0.9999999:www/py-html5lib \
		${PYTHON_PKGNAMEPREFIX}protobuf>=3.2.0:devel/py-protobuf \
		${PYTHON_PKGNAMEPREFIX}wheel>=0.29.0:devel/py-wheel \
		${PYTHON_PKGNAMEPREFIX}mock>=1.3.0:devel/py-mock \
		${PYTHON_PKGNAMEPREFIX}six>=1.10.0:devel/py-six \
		${PYTHON_PKGNAMEPREFIX}backports.weakref>=0:devel/py-backports.weakref \
		${PYTHON_PKGNAMEPREFIX}werkzeug>=0.11.10:www/py-werkzeug

USE_GITHUB=	yes
GH_TUPLE=	amutu:tensorflow_third_party:c528072:tf/tensorflow_third_party
USES=		python:2.7+ shebangfix
BAZEL_BOOT=	--output_user_root=${WRKSRC}/bazel_ot --batch

SHEBANG_GLOB=	*.py

.include <bsd.port.pre.mk>

#clang has this check enabled by default,disable it
#see: https://github.com/tensorflow/tensorflow/issues/8894
.if ${ARCH} == "i386"
BAZEL_COPT+=	--copt=-Wno-c++11-narrowing
.endif

post-patch:
	(cd ${WRKSRC} && \
	${REINPLACE_CMD} "s#bazel \([cf]\)#echo bazel ${BAZEL_BOOT} \1#g" \
	configure && \
	${REINPLACE_CMD} "s#tensorflow_third_party#${WRKSRC}/&#g" \
	WORKSPACE tensorflow/workspace.bzl)

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
		TF_NEED_VERBS=N \
		./configure)

do-build:
	(cd ${WRKSRC} && bazel ${BAZEL_BOOT} info && \
		bazel ${BAZEL_BOOT} build ${BAZEL_COPT} --config=opt \
		//tensorflow/tools/pip_package:build_pip_package --verbose_failures)
	(cd ${WRKSRC} && ${SETENV} TMPDIR=${WRKDIR} \
		bazel-bin/tensorflow/tools/pip_package/build_pip_package \
		${WRKDIR}/whl)

do-install:
	@${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}
	@${MKDIR} ${WRKDIR}/tmp
	@${UNZIP_NATIVE_CMD} -d ${WRKDIR}/tmp ${WRKDIR}/whl/${PORTNAME}-${PORTVERSION}-*.whl
	@${FIND} ${WRKDIR}/tmp -name "*.so*" | ${XARGS} ${STRIP_CMD}
	cd ${WRKDIR}/tmp && ${COPYTREE_SHARE} ${PORTNAME}-${PORTVERSION}.dist-info \
		${STAGEDIR}${PYTHON_SITELIBDIR}
	cd ${WRKDIR}/tmp/${PORTNAME}-${PORTVERSION}.data/purelib && \
		${COPYTREE_SHARE} . ${STAGEDIR}${PYTHON_SITELIBDIR}

.include <bsd.port.post.mk>
