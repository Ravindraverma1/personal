#################################################################################################
# This script does the following:
# - unpacks deploy_cv_service.zip
# - replaces contents from cv-rest-api into unarchived directory
# - repacks deploy_cv_service.zip
#################################################################################################
import os
import sys
from shutil import unpack_archive, make_archive, rmtree, copyfile, copytree, ignore_patterns

def repack_archive(existing_archive, src_dir_path):
    try:
        print("Repack archive...START")
        base_dir = "/tmp/axdeploy"
        if os.path.exists(base_dir) is True:
            rmtree(base_dir)
        os.makedirs(base_dir)
        unpack_archive(existing_archive, base_dir)
        dest_dir_path = next(os.walk(base_dir))[0]
        src_dir_path = next(os.walk(src_dir_path))[0]
        src_dir_list = next(os.walk(src_dir_path))[1]
        src_file_list = next(os.walk(src_dir_path))[2]
        for src_file in src_file_list:
            src = os.path.join(src_dir_path, src_file)
            dest = os.path.join(dest_dir_path, src_file)
            if os.path.exists(dest) is True:
                os.remove(dest)
            copyfile(src, dest)
        for src_dir in src_dir_list:
            if src_dir == "__pycache__":
                continue
            src = os.path.join(src_dir_path, src_dir)
            dest = os.path.join(dest_dir_path, src_dir)
            if os.path.exists(dest) is True:
                rmtree(dest)
            copytree(src, dest, ignore = ignore_patterns("__pycache__"))

        os.chdir("/tmp")
        if os.path.exists("deploy_cv_service.zip") is True:
            os.remove("deploy_cv_service.zip")
        make_archive("deploy_cv_service", "zip", "axdeploy/")        
        os.remove(existing_archive)        
        copyfile("/tmp/deploy_cv_service.zip", existing_archive)
        print("Repack archive...SUCCESS")

    except Exception as e:
        print("Repack archive...FAILED")
        sys.exit(e)

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # repack_archive(os.path.abspath("..\\lambdas\\deploy_cv_service.zip"), 
    #                 os.path.abspath("..\\lambdas\\cv-rest-api"))

    repack_archive(os.path.abspath("../lambdas/deploy_cv_service.zip"), 
                    os.path.abspath("../lambdas/cv-rest-api"))
