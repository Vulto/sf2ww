include_directories("${PROJECT_SOURCE_DIR}/RedHammer")
include_directories("${PROJECT_SOURCE_DIR}/FistBlue")
include_directories("${CMOCKA_INCLUDE_DIR}")

add_executable(test-redhammer main.c test_redhammer.c test_sf2types.c ${PROJECT_SOURCE_DIR}/RedHammer/redhammer.c)
add_test(test-redhammer test-redhammer)
target_link_libraries(test-redhammer ${CMOCKA_LIBRARY})
