############################################################################
#
# Copyright (c) 2015 Mark Charlebois. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name PX4 nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

# Overview:
# Hexagon/QuRT apps are built in 2 parts, the part that runs on the
# application (apps) processor, and the library that is invoked on the DSP.
#
# PREREQUISITES:
#
# Environment variables:
#	HEXAGON_TOOLS_ROOT
#	HEXAGON_SDK_ROOT
#

set(TOOLS_ERROR_MSG 
		"The HexagonTools version 6.4.X or 7.2.X must be installed and the environment variable HEXAGON_TOOLS_ROOT must be set"
		"(e.g. export HEXAGON_TOOLS_ROOT=$ENV{HOME}/Qualcomm/HEXAGON_Tools/7.2.10/Tools)")

if ("$ENV{HEXAGON_TOOLS_ROOT}" STREQUAL "")
	message(FATAL_ERROR ${TOOLS_ERROR_MSG})
else()
	set(HEXAGON_TOOLS_ROOT $ENV{HEXAGON_TOOLS_ROOT})
endif()

if ("$ENV{HEXAGON_SDK_ROOT}" STREQUAL "")
	message(FATAL_ERROR "HEXAGON_SDK_ROOT not set")
endif()

set(HEXAGON_SDK_ROOT $ENV{HEXAGON_SDK_ROOT})

set(FASTRPC_DSP_INCLUDES
	${HEXAGON_SDK_ROOT}/inc
	${HEXAGON_SDK_ROOT}/inc/stddef
	${HEXAGON_SDK_ROOT}/lib/common/rpcmem
	${HEXAGON_SDK_ROOT}/lib/common/remote/ship/hexagon_Debug
	)

set(FASTRPC_ARM_LINUX_INCLUDES
	-I${HEXAGON_SDK_ROOT}/inc/stddef
	-I${HEXAGON_SDK_ROOT}/lib/common/rpcmem
	-I${HEXAGON_SDK_ROOT}/lib/common/adspmsgd/ship/UbuntuARM_Debug
	-I${HEXAGON_SDK_ROOT}/lib/common/remote/ship/UbuntuARM_Debug
	)

set(FASTRPC_ARM_LIBS 
	-L${HEXAGON_SDK_ROOT}/lib/common/remote/ship/UbuntuARM_Debug -ladsprpc
	${HEXAGON_SDK_ROOT}/lib/common/rpcmem/UbuntuARM_Debug/rpcmem.a
	)
	
include_directories(
	${CMAKE_CURRENT_BINARY_DIR}
	)

function(FASTRPC_STUB_GEN IDLFILE)
	get_filename_component(FASTRPC_IDL_NAME ${IDLFILE} NAME_WE)
	get_filename_component(FASTRPC_IDL_PATH ${IDLFILE} ABSOLUTE)

	# Run the IDL compiler to generate the stubs
	add_custom_command(
		OUTPUT ${FASTRPC_IDL_NAME}.h ${FASTRPC_IDL_NAME}_skel.c ${FASTRPC_IDL_NAME}_stub.c
		DEPENDS ${FASTRPC_IDL_PATH}
		COMMAND "${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic" "-mdll" "-I" "${HEXAGON_SDK_ROOT}/inc/stddef" "${FASTRPC_IDL_PATH}"
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)

	message("Generated generate_${FASTRPC_IDL_NAME}_stubs target")

	add_custom_target(generate_${FASTRPC_IDL_NAME}_stubs ALL
		DEPENDS ${FASTRPC_IDL_NAME}.h ${FASTRPC_IDL_NAME}_skel.c ${FASTRPC_IDL_NAME}_stub.c
		)

	set_source_files_properties(
		${FASTRPC_IDL_NAME}.h
		${FASTRPC_IDL_NAME}_skel.c
		${FASTRPC_IDL_NAME}_stub.c
		PROPERTIES
		GENERATED TRUE
		)
endfunction()
