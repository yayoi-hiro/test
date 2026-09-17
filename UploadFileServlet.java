import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

@WebServlet("/uploadF")
@MultipartConfig
public class UploadFileServlet extends HttpServlet {

    private static final String BASE_DIR = "C:\\Program Files\\Apache Software Foundation\\Tomcat 10.1\\webapps\\demo";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        // クエリパラメータから対象フォルダを取得
        String folder = request.getParameter("folder");

        if (folder == null || folder.length() == 0) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("対象フォルダが指定されていません。\n");
            return;
        }

        // 指定可能なフォルダを限定
        if (!folder.equals("text") && !folder.equals("test") && !folder.equals("sample")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("指定できるフォルダは text、test、sample のいずれかです。\n");
            return;
        }

        Part filePart = request.getPart("file");

        if (filePart == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("ファイルがありません。\n");
            return;
        }

        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();

        if (fileName.length() == 0) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("ファイル名がありません。\n");
            return;
        }

        // 指定されたフォルダを対象フォルダにする
        Path targetDir = Paths.get(BASE_DIR, folder);
        Path targetFile = targetDir.resolve(fileName).normalize();

        // 指定フォルダ以外へのアクセスを禁止
        if (!targetFile.getParent().equals(targetDir)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("不正なファイル名です。\n");
            return;
        }

        // ファイルが存在しなければエラー
        if (!Files.exists(targetFile) || !Files.isRegularFile(targetFile)) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.setContentType("text/plain; charset=UTF-8");
            response.getWriter().write("書き換え対象のファイルが存在しません。\n");
            return;
        }

        // 既存ファイルを上書き
        try (InputStream input = filePart.getInputStream()) {
            Files.copy(input, targetFile, StandardCopyOption.REPLACE_EXISTING);
        }

        response.setContentType("text/plain; charset=UTF-8");
        response.getWriter().write("ファイルを書き換えました: " + folder + "\\" + fileName + "\n");
    }
}
