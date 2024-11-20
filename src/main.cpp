#include <boost/algorithm/string.hpp>
#include <boost/algorithm/string/trim.hpp>
#include <chrono>
#include <csignal>
#include <cstdlib>
#include <format>
#include <fstream>
#include <iostream>
#include <yaml-cpp/yaml.h>

struct Question {
  std::string q;
  std::string a;
  long next;  // Timestamp
  int repeat; // In hours
};

std::string filename;
std::vector<Question> questions;

void save(int sig) {
  std::cout << "SAVING" << std::endl;
  std::ofstream out(filename, std::ios_base::out);
  for (Question question : questions) {
    std::string output =
        std::format("- q: {}\n  a: {}\n  next: {}\n  repeat: {}\n", question.q,
                    question.a, question.next, question.repeat);
    out.write(output.c_str(), output.size());
  }
  out.close();
  exit(0);
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cout << "Usage: karten <YAML_FILENAME>" << std::endl;
    exit(1);
  }

  filename = std::string(argv[1]);
  YAML::Node data = YAML::LoadFile(filename);

  for (int i = 0; i < data.size(); i++) {
    questions.push_back(Question{
        .q = data[i]["q"].as<std::string>(),
        .a = data[i]["a"].as<std::string>(),
        .next = data[i]["next"].as<long>(),
        .repeat = data[i]["repeat"].as<int>(),
    });
  }

  signal(SIGINT, save);

  std::string input;
  while (true) {
    const long now =
        std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());

    bool found = false;
    for (Question &question : questions) {
      if (question.next > now) {
        break;
      }

      found = true;
      std::cout << question.q << std::endl;
      std::getline(std::cin, input);
      boost::algorithm::trim(input);

      if (input == question.a) {
        question.next = now + question.repeat * 3600;
        question.repeat *= 2;
        std::cout << "CORRECT\n" << std::endl;
      } else {
        question.next = now;
        question.repeat = 1;
        std::cout << std::endl;
      }
    }

    if (!found) {
      std::cout << "ALL CARDS ARE UP TO DATE" << std::endl;
      save(0);
    }
  }
}
