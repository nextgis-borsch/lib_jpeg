

execute_process(COMMAND ${TEST_APP} ${TEST_ARG1} ${TEST_ARG2} ${TEST_ARG3} ${TEST_ARG4} ${TEST_ARG5} ${TEST_ARG6} ${TEST_ARG7} ${TEST_ARG8}
                RESULT_VARIABLE HAD_ERROR
                )
if(HAD_ERROR)
    message(FATAL_ERROR "Test ${TEST_NAME} failed - ${HAD_ERROR}")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files
    ${TEST_COMPARE1}
    ${TEST_COMPARE2}
    RESULT_VARIABLE DIFFERENT)
if(DIFFERENT)
    message(FATAL_ERROR "Test ${TEST_NAME} failed - files differ")
endif()
